import Foundation
import CoreLocation
@preconcurrency import MapKit
import OSLog

// MARK: - WizPath Service
@MainActor
final class WizPathService {
    private let cache = WizPathCache()
    private let weatherRepository: WeatherRepository
    private let locationRepository: LocationRepository

    init(
        weatherRepository: WeatherRepository,
        locationRepository: LocationRepository
    ) {
        self.weatherRepository = weatherRepository
        self.locationRepository = locationRepository
    }

    // MARK: - Main Route Calculation

    func calculateRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TravelMode,
        departureTime: Date
    ) async throws -> WizPathRoute {
        // Check cache first
        if let cached = cache.route(origin: origin, destination: destination, mode: mode) {
            AppLogger.wizPath.info("Using cached route")
            return cached
        }

        AppLogger.wizPath.info("Calculating route from (\(origin.latitude),\(origin.longitude)) to (\(destination.latitude),\(destination.longitude))")

        let mkRoute = try await calculateMKRoute(
            origin: origin,
            destination: destination,
            mode: mode,
            departureTime: departureTime
        )

        let segments = interpolateSegments(
            route: mkRoute,
            mode: mode,
            departureTime: departureTime
        )

        // Attach real weather data to each segment
        let segmentsWithWeather = try await attachWeatherDataToSegments(segments: segments)

        let route = WizPathRoute(
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

        cache.store(route: route)
        AppLogger.wizPath.info("Route calculated successfully: \(route.segments.count) segments, \(route.totalDuration) seconds")
        return route
    }

    // MARK: - Route Calculation via MKDirections

    private func calculateMKRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TravelMode,
        departureTime: Date
    ) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = mode.mkTransportType
        request.departureDate = departureTime
        request.requestsAlternateRoutes = true

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()
            guard let route = response.routes.first else {
                throw WizPathError.routeUnavailable
            }
            return route
        } catch let error as MKError {
            // MapKit error codes (raw values for broader compatibility)
            // MKErrorDirectionsNotAvailable = 4, MKErrorServerFailure = 2
            let nsError = error as NSError
            switch nsError.code {
            case 4: // MKErrorDirectionsNotAvailable
                throw WizPathError.destinationUnreachable
            case 2, 5: // MKErrorServerFailure, MKErrorNetworkFailure
                throw WizPathError.routeUnavailable
            default:
                throw WizPathError.routeUnavailable
            }
        }
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

    // MARK: - Real Weather Attachment via WeatherRepository

    private func attachWeatherDataToSegments(segments: [WizPathSegment]) async throws -> [WizPathSegment] {
        var updatedSegments = segments

        // Group segments by hour to reduce WeatherKit API calls
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: updatedSegments.indices) { index in
            calendar.component(.hour, from: segments[index].estimatedArrival)
        }

        var weatherCache: [Int: SegmentWeather] = [:]

        for (hour, indices) in grouped {
            if let firstIndex = indices.first {
                let segment = segments[firstIndex]
                let coord = LocationCoordinate(
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
                    AppLogger.wizPath.error("Weather fetch failed for segment at hour \(hour): \(error.localizedDescription)")
                    // Fallback: use time-based estimation
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

    /// Convert WeatherSnapshot to SegmentWeather at a specific time
    private func segmentWeather(from snapshot: WeatherSnapshot, at date: Date) -> SegmentWeather {
        // Try to find the hourly forecast closest to our arrival time
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

        // Fallback to current weather
        return SegmentWeather(
            condition: mapConditionCode(snapshot.current.symbolName ?? snapshot.current.conditionCode ?? "clear"),
            temperature: snapshot.current.temperatureCelsius,
            precipitationChance: snapshot.current.precipitationChance ?? 0,
            windSpeed: snapshot.current.windSpeedKph ?? 0,
            visibility: 10,
            severity: mapConditionCode(snapshot.current.symbolName ?? snapshot.current.conditionCode ?? "clear").severity
        )
    }

    /// Map WeatherKit condition codes to SegmentWeatherCondition
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

    /// Fallback weather estimation when API fails
    private func estimatedWeather(for coordinate: CLLocationCoordinate2D, at date: Date) -> SegmentWeather {
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        // Use minute-based deterministic variation instead of random
        let variation = Double(minute % 6) - 2.5

        let baseTemp: Double
        switch hour {
        case 5..<9:  baseTemp = 14 + variation
        case 9..<13: baseTemp = 20 + variation * 1.5
        case 13..<17: baseTemp = 25 + variation * 2
        case 17..<21: baseTemp = 19 + variation
        default:      baseTemp = 12 + variation
        }

        let isNight = hour < 6 || hour >= 21
        let condition: SegmentWeatherCondition = isNight ? .clear : .partlyCloudy

        // Deterministic wind speed based on hour
        let windSpeed: Double = 5 + Double((hour * 7 + 3) % 14)

        return SegmentWeather(
            condition: condition,
            temperature: baseTemp,
            precipitationChance: isNight ? 0.05 : 0.15,
            windSpeed: windSpeed,
            visibility: isNight ? 12 : 10,
            severity: condition.severity
        )
    }

    // MARK: - Traffic Update

    func updateWithCurrentTraffic(route: WizPathRoute) async throws -> WizPathRoute {
        try await calculateRoute(
            origin: route.origin,
            destination: route.destination,
            mode: route.travelMode,
            departureTime: Date()
        )
    }

    // MARK: - Recent Destinations

    func saveRecentDestination(name: String, coordinate: CLLocationCoordinate2D) {
        var recents = loadRecentDestinations()
        let new = RecentDestination(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
        recents.removeAll { $0.name == name }
        recents.insert(new, at: 0)
        if recents.count > 10 { recents = Array(recents.prefix(10)) }

        if let data = try? JSONEncoder().encode(recents) {
            Foundation.UserDefaults.standard.set(data, forKey: AppKeys.UserDefaults.wizPathRecentDestinations)
        }
    }

    func loadRecentDestinations() -> [RecentDestination] {
        guard let data = Foundation.UserDefaults.standard.data(forKey: AppKeys.UserDefaults.wizPathRecentDestinations),
              let recents = try? JSONDecoder().decode([RecentDestination].self, from: data) else {
            return []
        }
        return recents
    }

    // MARK: - Location Services

    func getCurrentLocation() async throws -> LocationCoordinate {
        return try await locationRepository.getCurrentLocation()
    }
}

// MARK: - Recent Destination Model
struct RecentDestination: Codable, Hashable, Identifiable {
    let name: String
    let latitude: Double
    let longitude: Double

    var id: String { name }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - WizPath Cache

final class WizPathCache {
    static let shared = WizPathCache()

    private var routeCache: [String: WizPathRoute] = [:]
    private let queue = DispatchQueue(label: "com.forewiz.wizpath.cache", qos: .utility)

    fileprivate init() {}

    func store(route: WizPathRoute) {
        queue.async {
            let key = "\(route.origin.latitude),\(route.origin.longitude)|\(route.destination.latitude),\(route.destination.longitude)|\(route.travelMode.rawValue)"
            self.routeCache[key] = route
        }
    }

    func route(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, mode: TravelMode) -> WizPathRoute? {
        queue.sync {
            let key = "\(origin.latitude),\(origin.longitude)|\(destination.latitude),\(destination.longitude)|\(mode.rawValue)"
            return self.routeCache[key]
        }
    }

    func clear() {
        queue.sync {
            self.routeCache.removeAll()
        }
    }
}
