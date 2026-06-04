import Foundation
import CoreLocation
@preconcurrency import MapKit
import OSLog
@preconcurrency import ActivityKit

// MARK: - WizPath Service
@MainActor
public final class WizPathService {
    private let cache = WizPathCache()
    private let weatherRepository: WizPathWeatherSource
    private let locationRepository: WizPathLocationSource

    public init(
        weatherRepository: WizPathWeatherSource,
        locationRepository: WizPathLocationSource
    ) {
        self.weatherRepository = weatherRepository
        self.locationRepository = locationRepository
    }

    // MARK: - Main Route Calculation

    public func calculateRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TravelMode,
        departureTime: Date,
        avoidTollRoads: Bool = false
    ) async throws -> WizPathRoute {
        let (route, _) = try await calculateRouteWithCandidates(
            origin: origin,
            destination: destination,
            mode: mode,
            departureTime: departureTime,
            avoidTollRoads: avoidTollRoads
        )
        return route
    }

    /// Calculate route and return all scored candidates for comparison.
    /// Returns (bestRoute, allCandidates).
    public func calculateRouteWithCandidates(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TravelMode,
        departureTime: Date,
        avoidTollRoads: Bool = false
    ) async throws -> (best: WizPathRoute, candidates: [ScoredRouteCandidate]) {
        if let cached = await cache.route(origin: origin, destination: destination, mode: mode, avoidTollRoads: avoidTollRoads) {
            AppLogger.wizPath.info("Using cached route")
            return (cached, [])
        }
        if avoidTollRoads {
            AppLogger.wizPath.info("Toll avoidance enabled — bypassing cache for fresh calculation")
        }

        AppLogger.wizPath.info("Calculating route from (\(origin.latitude, privacy: .private),\(origin.longitude, privacy: .private)) to (\(destination.latitude, privacy: .private),\(destination.longitude, privacy: .private))")

        let mkRoutes = try await calculateAllMKRoutes(
            origin: origin,
            destination: destination,
            mode: mode,
            departureTime: departureTime
        )

        AppLogger.wizPath.info("Found \(mkRoutes.count) alternate route(s) — scoring each for weather fitness...")

        // Build a ScoredRouteCandidate for each MKRoute
        var candidates: [ScoredRouteCandidate] = []

        for mkRoute in mkRoutes {
            let segments = interpolateSegments(
                route: mkRoute,
                mode: mode,
                departureTime: departureTime
            )
            let segmentsWithWeather = try await attachWeatherDataToSegments(segments: segments)

            // Detect toll roads (advisory notices)
            let hasTollRoads = detectTollRoad(from: mkRoute)

            // If avoiding tolls, penalize heavily
            let tollPenalty = (avoidTollRoads && hasTollRoads) ? 40 : 0

            let candidate = WizPathRoute(
                id: UUID(),
                origin: origin,
                destination: destination,
                travelMode: mode,
                departureTime: departureTime,
                segments: segmentsWithWeather,
                totalDuration: mkRoute.expectedTravelTime,
                totalDistance: mkRoute.distance,
                polyline: mkRoute.polyline
            )

            // Detect traffic congestion level
            let congestion = detectTrafficCongestion(from: mkRoute)

            let severeCount = segmentsWithWeather.filter { $0.weather?.severity == .severe }.count
            let cautionCount = segmentsWithWeather.filter { $0.weather?.severity == .caution }.count

            let baseScore = scoreRoute(candidate)
            let finalScore = max(0, baseScore - tollPenalty - congestion.trafficPenalty)

            let scored = ScoredRouteCandidate(
                route: candidate,
                score: finalScore,
                trafficCongestion: congestion.level,
                hasTollRoads: hasTollRoads,
                severeSegmentCount: severeCount,
                cautionSegmentCount: cautionCount
            )

            candidates.append(scored)
            AppLogger.wizPath.info("  Route #\(candidates.count): score=\(finalScore), duration=\(Int(mkRoute.expectedTravelTime / 60))min, risk=\(candidate.overallRisk.rawValue), toll=\(hasTollRoads), traffic=\(congestion.level.rawValue)")
        }

        // Sort: higher score first, ties broken by shorter duration
        candidates.sort { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.route.totalDuration < rhs.route.totalDuration
        }

        guard let best = candidates.first else {
            throw WizPathError.routeUnavailable
        }

        await cache.store(route: best.route, avoidTollRoads: avoidTollRoads)
        AppLogger.wizPath.info("Best route selected: score=\(best.score), \(best.route.segments.count) segments, \(Int(best.route.totalDuration / 60)) min")
        return (best.route, candidates)
    }

    // MARK: - Route Calculation via MKDirections

    /// Returns all alternate routes from MKDirections, up to a sensible limit.
    /// Includes a platform-aware timeout to prevent hangs on simulator/slow networks.
    private func calculateAllMKRoutes(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TravelMode,
        departureTime: Date
    ) async throws -> [MKRoute] {
        #if targetEnvironment(simulator)
        let mkTimeout: UInt64 = 45_000_000_000 // 45s — simulator MKDirections is notoriously slow
        #else
        let mkTimeout: UInt64 = 25_000_000_000 // 25s — real device is usually fast
        #endif

        return try await withThrowingTaskGroup(of: [MKRoute].self) { group in
            group.addTask {
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
                request.transportType = mode.mkTransportType
                request.departureDate = departureTime
                request.requestsAlternateRoutes = true

                let directions = MKDirections(request: request)
                let startTime = CFAbsoluteTimeGetCurrent()

                do {
                    let response = try await directions.calculate()
                    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                    AppLogger.wizPath.info("MKDirections completed in \(String(format: "%.1f", elapsed))s with \(response.routes.count) route(s)")
                    guard !response.routes.isEmpty else {
                        throw WizPathError.routeUnavailable
                    }
                    return Array(response.routes.prefix(4))
                } catch let error as MKError {
                    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                    AppLogger.wizPath.error("MKDirections failed after \(String(format: "%.1f", elapsed))s: \(error.localizedDescription)")
                    let nsError = error as NSError
                    switch nsError.code {
                    case 4:
                        throw WizPathError.destinationUnreachable
                    case 2, 5:
                        throw WizPathError.routeUnavailable
                    default:
                        throw WizPathError.routeUnavailable
                    }
                }
            }
            // ⏱️ Platform-aware timeout guard
            group.addTask {
                try await Task.sleep(nanoseconds: mkTimeout)
                #if targetEnvironment(simulator)
                AppLogger.wizPath.warning("MKDirections timed out after 45s (simulator)")
                #else
                AppLogger.wizPath.warning("MKDirections timed out after 25s (device)")
                #endif
                throw WizPathError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    /// Score a fully-built WizPathRoute so we can compare alternatives.
    /// Lower is worse. 100 = perfect, 0 = impassable.
    private func scoreRoute(_ route: WizPathRoute) -> Int {
        var score = 100

        // Severe segments are dangerous — heavy penalty per segment
        // Winter: snow/ice at sub-zero temps gets extra penalty (road closure risk)
        let severeSegments = route.segments.filter { $0.weather?.severity == .severe }
        for segment in severeSegments {
            let basePenalty = 30
            // Winter closure risk: snow/sleet + sub-zero temps = potential road closure
            if let weather = segment.weather, weather.temperature < -2 {
                if weather.condition == .snow || weather.condition == .sleet {
                    score -= basePenalty + 25 // Heavy penalty — roads may be closed
                } else {
                    score -= basePenalty + 10 // Ice risk
                }
            } else if let weather = segment.weather, weather.condition == .thunderstorm {
                score -= basePenalty + 15 // Storm — reduced visibility + danger
            } else {
                score -= basePenalty
            }
        }

        // Caution segments degrade the trip
        let cautionCount = route.segments.filter { $0.weather?.severity == .caution }.count
        score -= cautionCount * 15

        // Fair segments are mild but still not ideal
        let fairCount = route.segments.filter { $0.weather?.severity == .fair }.count
        score -= fairCount * 5

        // Duration penalty — prefer quicker routes when weather is equal
        let durationMinutes = Int(route.totalDuration / 60)
        score -= min(20, durationMinutes)

        // Cycling-specific wind penalty
        if route.travelMode == .cycling {
            let windSpeeds = route.segments.compactMap { $0.weather?.windSpeed }
            let avgWind = windSpeeds.reduce(0.0, +) / max(1.0, Double(windSpeeds.count))
            if avgWind > 20 {
                score -= Int(avgWind - 20) * 3
            }
            // Winter cycling gets extra penalty (unsafe)
            let minTemp = route.segments.compactMap { $0.weather?.temperature }.min() ?? 20
            if minTemp < 0 {
                score -= 35 // Cycling below freezing = high risk
            } else if minTemp < 5 {
                score -= 15
            }
        }

        return max(0, score)
    }

    /// Detect if an MKRoute includes toll roads.
    /// Uses Apple Maps' multi-language advisory notice text heuristic.
    private func detectTollRoad(from route: MKRoute) -> Bool {
        return detectTollRoadFromAdvisoryNotices(route)
    }

    /// Multi-language advisory notice toll detection (fallback).
    private func detectTollRoadFromAdvisoryNotices(_ route: MKRoute) -> Bool {
        for notice in route.advisoryNotices {
            let lower = notice.lowercased()
            if lower.contains("toll") || lower.contains("toll road") { return true }
            if lower.contains("ücretli") || lower.contains("paralı") || lower.contains("köprü") || lower.contains("otoyol ücret") { return true }
            if lower.contains("maut") || lower.contains("gebührenpflichtig") { return true }
            if lower.contains("péage") || lower.contains("payant") { return true }
            if lower.contains("peaje") || lower.contains("cobro") { return true }
            if lower.contains("pedaggio") { return true }
            if lower.contains("tol") || lower.contains("tolweg") { return true }
            if lower.contains("pedágio") { return true }
            if lower.contains("платный") { return true }
            if lower.contains("有料") { return true }
            if lower.contains("유료") { return true }
            if lower.contains("收费") { return true }
            if lower.contains("رسوم") { return true }
        }
        return false
    }

    /// Detect traffic congestion from MKRoute data.
    /// ✅ Uses MKDirections' built-in traffic-aware expectedTravelTime (which accounts for
    /// real-time traffic when departureDate is set) combined with speed-based heuristics.
    /// 
    /// Apple Maps' expectedTravelTime already incorporates traffic data when a departureDate
    /// is provided. We compare against distance-based free-flow estimates to extract a
    /// congestion ratio, then calibrate with multi-language advisory notice scanning.
    ///
    /// Returns level and a penalty for scoring.
    private func detectTrafficCongestion(from route: MKRoute) -> (level: TrafficCongestionLevel, trafficPenalty: Int) {
        let distanceKm = route.distance / 1000.0
        guard distanceKm > 0.1 else { return (.unknown, 0) }

        // Free-flow speed estimates by road type (km/h)
        // Highway: ~100 km/h, Arterial: ~60 km/h, Local: ~35 km/h
        let freeFlowSpeedKph: Double
        if distanceKm > 100 {
            freeFlowSpeedKph = 105  // Long-distance highway
        } else if distanceKm > 30 {
            freeFlowSpeedKph = 85   // Mixed highway
        } else if distanceKm > 10 {
            freeFlowSpeedKph = 60   // Arterial roads
        } else {
            freeFlowSpeedKph = 40   // City/local
        }

        let estimatedFreeFlowTime: TimeInterval = (distanceKm / freeFlowSpeedKph) * 3600.0
        let actualTime = route.expectedTravelTime
        let ratio = actualTime / estimatedFreeFlowTime

        // Multi-language advisory notice scanning for traffic-related messages
        let hasTrafficNotice = route.advisoryNotices.contains { notice in
            let lower = notice.lowercased()
            return lower.contains("traffic") || lower.contains("congestion") ||
                   lower.contains("delay") || lower.contains("heavy") ||
                   lower.contains("slow") || lower.contains("stau") ||  // German
                   lower.contains("embouteillage") || lower.contains("bouchon") ||  // French
                   lower.contains("tráfico") || lower.contains("atasco") ||  // Spanish
                   lower.contains("trafik") || lower.contains("yoğun") ||  // Turkish
                   lower.contains("ingorgo") || lower.contains("rallentamento")  // Italian
        }

        let level: TrafficCongestionLevel
        let trafficPenalty: Int

        if ratio >= 2.5 || (hasTrafficNotice && ratio >= 1.8) {
            level = .gridlock
            trafficPenalty = 35
        } else if ratio >= 1.8 || (hasTrafficNotice && ratio >= 1.4) {
            level = .heavy
            trafficPenalty = 20
        } else if ratio >= 1.4 {
            level = .moderate
            trafficPenalty = 8
        } else {
            level = .freeFlow
            trafficPenalty = 0
        }

        return (level, trafficPenalty)
    }

    // MARK: - Segment Interpolation

    private func interpolateSegments(
        route: MKRoute,
        mode: TravelMode,
        departureTime: Date
    ) -> [WizPathSegment] {
        let polyline = route.polyline
        let points = polyline.points()
        let pointCount = polyline.pointCount
        let totalDuration = route.expectedTravelTime
        let segmentInterval = mode.segmentInterval
        let numSegments = max(4, min(20, Int(totalDuration / segmentInterval)))

        var segments: [WizPathSegment] = []

        for i in 0..<numSegments {
            let progress = Double(i) / Double(numSegments - 1)
            let travelTime = totalDuration * progress
            let estimatedArrival = departureTime.addingTimeInterval(travelTime)
            let pointIndex = min(Int(Double(pointCount - 1) * progress), pointCount - 1)
            let coordinate = points[pointIndex].coordinate
            let distance = route.distance * progress

            segments.append(WizPathSegment(
                id: UUID(),
                coordinate: coordinate,
                estimatedArrival: estimatedArrival,
                distanceFromStart: distance,
                travelTime: travelTime,
                weather: nil
            ))
        }

        return segments
    }

    // MARK: - Real Weather Attachment

    private func attachWeatherDataToSegments(segments: [WizPathSegment]) async throws -> [WizPathSegment] {
        var updatedSegments = segments
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: updatedSegments.indices) { index in
            calendar.component(.hour, from: segments[index].estimatedArrival)
        }

        var weatherCache: [Int: SegmentWeather] = [:]

        for (hour, indices) in grouped {
            if let firstIndex = indices.first {
                let segment = segments[firstIndex]
                let coord = WizPathCoordinate(
                    latitude: segment.coordinate.latitude,
                    longitude: segment.coordinate.longitude
                )

                do {
                    let snapshot = try await weatherRepository.fetchWeather(for: coord)
                    let weather = segmentWeather(from: snapshot, at: segment.estimatedArrival)
                    weatherCache[hour] = weather

                    for index in indices {
                        updatedSegments[index].weather = weather
                    }
                } catch {
                    AppLogger.wizPath.error("Weather fetch failed for segment at hour \(hour): \(error.localizedDescription, privacy: .private)")
                    let fallback = estimatedWeather(for: segments[firstIndex].coordinate, at: segments[firstIndex].estimatedArrival)
                    weatherCache[hour] = fallback
                    for index in indices {
                        updatedSegments[index].weather = fallback
                    }
                }
            }
        }

        return updatedSegments
    }

    private func segmentWeather(from snapshot: WizPathWeatherSnapshot, at date: Date) -> SegmentWeather {
        let calendar = Calendar.current
        let targetHour = calendar.component(.hour, from: date)

        if let hourlyPoint = snapshot.hourly.first(where: {
            calendar.component(.hour, from: $0.date) == targetHour &&
            calendar.isDate($0.date, inSameDayAs: date)
        }) ?? snapshot.hourly.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {

            let condition = mapConditionCode(hourlyPoint.conditionCode ?? hourlyPoint.symbolName ?? "clear")
            let severity = condition.severity
            let precip = hourlyPoint.precipitationChance ?? 0
            let wind = hourlyPoint.windSpeedKph ?? 0

            return SegmentWeather(
                condition: condition,
                temperature: hourlyPoint.temperatureCelsius,
                precipitationChance: precip,
                windSpeed: wind,
                visibility: visibility(for: condition, precipitation: precip),
                severity: severity
            )
        }

        return SegmentWeather(
            condition: mapConditionCode(snapshot.current.symbolName ?? snapshot.current.conditionCode ?? "clear"),
            temperature: snapshot.current.temperatureCelsius,
            precipitationChance: snapshot.current.precipitationChance ?? 0,
            windSpeed: snapshot.current.windSpeedKph ?? 0,
            visibility: 10,
            severity: mapConditionCode(snapshot.current.symbolName ?? snapshot.current.conditionCode ?? "clear").severity
        )
    }

    private func mapConditionCode(_ code: String) -> SegmentWeatherCondition {
        let lower = code.lowercased()
        if lower.contains("thunder") || lower.contains("storm") || lower.contains("bolt") { return .thunderstorm }
        if lower.contains("heavy") && lower.contains("rain") { return .heavyRain }
        if lower.contains("rain") || lower.contains("drizzle") { return .rain }
        if lower.contains("sleet") { return .sleet }
        if lower.contains("snow") || lower.contains("flurry") { return .snow }
        if lower.contains("fog") || lower.contains("haze") || lower.contains("mist") { return .fog }
        if lower.contains("cloudy") || lower.contains("overcast") || lower.contains("mostly.cloud") { return .cloudy }
        if lower.contains("partly.cloudy") || lower.contains("partly.cloud") { return .partlyCloudy }
        if lower.contains("wind") { return .windy }
        if lower.contains("clear") || lower.contains("sun") || lower.contains("fair") { return .clear }
        return .clear
    }

    private func visibility(for condition: SegmentWeatherCondition, precipitation: Double) -> Double {
        switch condition {
        case .fog: return max(0.5, 2.0 - precipitation * 1.5)
        case .heavyRain, .thunderstorm: return max(3.0, 6.0 - precipitation * 3.0)
        case .rain, .snow, .sleet: return max(5.0, 10.0 - precipitation * 5.0)
        case .cloudy: return max(8.0, 12.0 - precipitation * 2.0)
        default: return 15
        }
    }

    /// 🌤️ Improved fallback weather estimation using seasonal + geographic heuristics.
    /// When real weather data is unavailable, this returns a reasonable estimate based on
    /// the location's latitude, time of year, and time of day.
    /// The fallback is clearly labeled as "estimated" so the UI can indicate uncertainty.
    private func estimatedWeather(for coordinate: CLLocationCoordinate2D, at date: Date) -> SegmentWeather {
        AppLogger.wizPath.warning("⚠️ Using ESTIMATED (fallback) weather — real API unavailable")

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let month = calendar.component(.month, from: date)
        let isNight = hour < 6 || hour >= 21

        // Latitude-based temperature estimation (simple model)
        let absLat = abs(coordinate.latitude)
        // Base temperature by latitude: equator ~30°C, poles ~0°C
        let latBaseTemp = 30.0 - (absLat / 90.0) * 30.0

        // Seasonal adjustment: northern hemisphere summer (months 6-8) is warmest
        let isNorthernHemis = coordinate.latitude >= 0
        let seasonalOffset: Double
        if isNorthernHemis {
            // Summer peak in July (month 7)
            seasonalOffset = -cos(Double(month) * .pi / 6.0) * 10.0
        } else {
            // Summer peak in January (month 1)
            let adjustedMonth = month <= 6 ? month + 12 : month
            seasonalOffset = -cos(Double(adjustedMonth) * .pi / 6.0) * 10.0
        }

        // Night cooling
        let nightCooling = isNight ? 5.0 : 0.0
        let estimatedTemp = max(-10, min(45, latBaseTemp + seasonalOffset - nightCooling))

        // Precipitation estimation: higher near equator, lower at poles
        let basePrecip: Double
        if absLat < 23.5 {
            basePrecip = 0.4  // Tropical
        } else if absLat < 45 {
            basePrecip = 0.25 // Temperate
        } else {
            basePrecip = 0.15 // Polar
        }
        // Seasonal precip adjustment
        let precipSeasonal = basePrecip + (seasonalOffset > 0 ? 0.1 : -0.05)
        let estimatedPrecip = max(0, min(1, precipSeasonal + (isNight ? -0.05 : 0.0)))

        // Condition estimation
        let condition: SegmentWeatherCondition
        if estimatedPrecip > 0.6 {
            condition = .rain
        } else if estimatedPrecip > 0.3 {
            condition = isNight ? .cloudy : .partlyCloudy
        } else if isNight {
            condition = .clear
        } else {
            condition = .partlyCloudy
        }

        // Wind estimate: moderate by default
        let windBase: Double
        if absLat > 60 {
            windBase = 25 // Polar winds
        } else if absLat > 30 {
            windBase = 15 // Mid-latitude westerlies
        } else {
            windBase = 10 // Tropics
        }
        let estimatedWind = windBase + (estimatedPrecip * 15)

        return SegmentWeather(
            condition: condition,
            temperature: estimatedTemp,
            precipitationChance: estimatedPrecip,
            windSpeed: estimatedWind,
            visibility: condition == .rain ? 8 : 12,
            severity: condition.severity
        )
    }

    // MARK: - Traffic Update

    public func updateWithCurrentTraffic(route: WizPathRoute, avoidTollRoads: Bool = false) async throws -> WizPathRoute {
        let newRoute = try await calculateRoute(
            origin: route.origin,
            destination: route.destination,
            mode: route.travelMode,
            departureTime: Date(),
            avoidTollRoads: avoidTollRoads
        )
        await updateRouteActivity(with: newRoute)
        return newRoute
    }

    // MARK: - Recent Destinations

    public func saveRecentDestination(name: String, coordinate: CLLocationCoordinate2D) {
        var recents = loadRecentDestinations()
        let new = RecentDestination(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
        recents.removeAll { $0.name == name }
        recents.insert(new, at: 0)
        if recents.count > 10 { recents = Array(recents.prefix(10)) }

        if let data = try? JSONEncoder().encode(recents) {
            Foundation.UserDefaults.standard.set(data, forKey: AppKeys.UserDefaults.wizPathRecentDestinations)
        }
    }

    public func loadRecentDestinations() -> [RecentDestination] {
        guard let data = Foundation.UserDefaults.standard.data(forKey: AppKeys.UserDefaults.wizPathRecentDestinations),
              let recents = try? JSONDecoder().decode([RecentDestination].self, from: data) else {
            return []
        }
        return recents
    }

    // MARK: - Location Services

    public func getCurrentLocation() async throws -> WizPathCoordinate {
        let coord = try await locationRepository.getCurrentLocation()
        return coord
    }

    // MARK: - Live Activity HUD Integration

    /// Whether Live Activities are supported on this device.
    public var areLiveActivitiesSupported: Bool {
        if #available(iOS 18.0, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }

    /// Start a Live Activity HUD for the given route.
    public func startRouteActivity(route: WizPathRoute, originName: String, destinationName: String) async {
        guard #available(iOS 18.0, *) else { return }
        await WizPathHUDManager.shared.startRouteActivity(origin: originName, destination: destinationName, mode: route.travelMode)
        await updateRouteActivity(with: route)
    }

    /// Update the Live Activity HUD with the latest route data.
    public func updateRouteActivity(with route: WizPathRoute) async {
        guard #available(iOS 18.0, *) else { return }
        let state = contentState(for: route)
        await WizPathHUDManager.shared.updateHUD(with: state)
    }

    /// End the current route's Live Activity HUD.
    public func endRouteActivity() async {
        guard #available(iOS 18.0, *) else { return }
        await WizPathHUDManager.shared.endRouteActivity()
    }

    @available(iOS 18.0, *)
    private func contentState(for route: WizPathRoute) -> WizPathHUDLiveActivityAttributes.ContentState {
        let severeCount = route.segments.filter { $0.weather?.severity == .severe }.count
        let cautionCount = route.segments.filter { $0.weather?.severity == .caution }.count
        let hazardCount = severeCount + cautionCount

        let safetyScore = computeHUDSafetyScore(for: route)

        let nextSafeStop = route.segments.first { seg in
            guard let weather = seg.weather else { return false }
            return weather.severity == .good || weather.severity == .fair
        }

        let weatherSymbol = route.segments.first?.weather?.iconName ?? "questionmark"
        let riskLabel = route.overallRisk.localizedTitle
        let distanceRemaining = route.totalDistance
        let estimatedArrival = route.segments.last?.estimatedArrival ?? route.departureTime.addingTimeInterval(route.totalDuration)

        return WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: safetyScore,
            hazardCount: hazardCount,
            totalDuration: route.totalDuration,
            distanceRemaining: distanceRemaining,
            nextSafeStopName: nextSafeStop?.placeName,
            nextSafeStopEta: nextSafeStop?.estimatedArrival,
            routeRiskLabel: riskLabel,
            weatherConditionSymbol: weatherSymbol,
            estimatedArrival: estimatedArrival
        )
    }

    private func computeHUDSafetyScore(for route: WizPathRoute) -> Int {
        var score = 100
        for segment in route.segments {
            guard let weather = segment.weather else { continue }
            switch weather.severity {
            case .severe:
                score -= 30
            case .caution:
                score -= 15
            case .fair:
                score -= 5
            case .good:
                break
            }
        }
        return max(0, score)
    }
}

// MARK: - Recent Destination Model
public struct RecentDestination: Codable, Hashable, Identifiable {
    public let name: String
    public let latitude: Double
    public let longitude: Double

    public var id: String { name }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - WizPath Cache
//// Cache TTL değeri artık `defaultTTL` parametresi ile yapılandırılabilir.
/// Varsayılan: 15 dakika. ViewModel tarafından da override edilebilir.
public actor WizPathCache {
    public static let shared = WizPathCache()

    private struct CacheEntry {
        let route: WizPathRoute
        let timestamp: Date
        let ttl: TimeInterval
        var isExpired: Bool { Date().timeIntervalSince(timestamp) > ttl }
    }

    private var routeCache: [String: CacheEntry] = [:]
    /// Root TTL override (nil = use each entry's own TTL).
    /// Bu değer, `WizPathService` veya ViewModel tarafından değiştirilebilir.
    public var defaultTTL: TimeInterval? = nil

    public init() {}

    /// Cache route with optional TTL.
    /// - Parameters:
    ///   - ttl: Cache süresi (saniye). Varsayılan: 15 dk (900).
    public func store(route: WizPathRoute, avoidTollRoads: Bool = false, ttl: TimeInterval = 900) {
        let tollSuffix = avoidTollRoads ? "|no_tolls" : ""
        let key = "\(route.origin.latitude),\(route.origin.longitude)|\(route.destination.latitude),\(route.destination.longitude)|\(route.travelMode.rawValue)\(tollSuffix)"
        let effectiveTTL = defaultTTL ?? ttl
        self.routeCache[key] = CacheEntry(route: route, timestamp: Date(), ttl: effectiveTTL)
        // Periodic cleanup: remove expired entries
        if self.routeCache.count > 20 {
            self.routeCache = self.routeCache.filter { !$0.value.isExpired }
        }
    }

    public func route(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, mode: TravelMode, avoidTollRoads: Bool = false) -> WizPathRoute? {
        let tollSuffix = avoidTollRoads ? "|no_tolls" : ""
        let key = "\(origin.latitude),\(origin.longitude)|\(destination.latitude),\(destination.longitude)|\(mode.rawValue)\(tollSuffix)"
        guard let entry = self.routeCache[key], !entry.isExpired else {
            self.routeCache.removeValue(forKey: key)
            return nil
        }
        return entry.route
    }

    public func clear() {
        self.routeCache.removeAll()
    }
}
