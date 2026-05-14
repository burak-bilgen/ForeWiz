import Foundation
import CoreLocation
@preconcurrency import MapKit
import OSLog
import Combine

// MARK: - WizPath Service
@MainActor
final class WizPathService: ObservableObject {
    static let shared = WizPathService()
    
    private let weatherService: WeatherServiceProtocol
    private let cache: WizPathCache
    private let throttleManager: APIThrottleManager
    
    @Published var isCalculating = false
    @Published var currentRoute: WizPathRoute?
    @Published var error: WizPathError?
    
    private init(
        weatherService: WeatherServiceProtocol = WizPathWeatherService.shared,
        cache: WizPathCache = WizPathCache.shared,
        throttleManager: APIThrottleManager = APIThrottleManager()
    ) {
        self.weatherService = weatherService
        self.cache = cache
        self.throttleManager = throttleManager
    }
    
    // MARK: - Main Calculation Flow
    
    /// Calculate complete route with weather interpolation
    func calculateRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TravelMode,
        departureTime: Date
    ) async throws -> WizPathRoute {
        isCalculating = true
        defer { isCalculating = false }
        
        // Step 1: Get MKDirections route
        let mkRoute = try await calculateMKRoute(
            origin: origin,
            destination: destination,
            mode: mode
        )
        
        // Step 2: Break into time-based segments
        let segments = try await interpolateSegments(
            route: mkRoute,
            mode: mode,
            departureTime: departureTime
        )
        
        // Step 3: Fetch weather for each segment (throttled)
        let segmentsWithWeather = try await fetchWeatherForSegments(segments)
        
        // Step 4: Build WizPathRoute
        let wizPathRoute = WizPathRoute(
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
        
        self.currentRoute = wizPathRoute
        cache.store(route: wizPathRoute)
        
        return wizPathRoute
    }
    
    // MARK: - Route Calculation
    
    private func calculateMKRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TravelMode
    ) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = mode.mkTransportType
        request.departureDate = Date()
        
        // Request traffic-based ETA
        if mode == .car {
            request.requestsAlternateRoutes = true
        }
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            
            guard let route = response.routes.first else {
                throw WizPathError.routeUnavailable
            }
            
            return route
        } catch {
            throw mapMKError(error)
        }
    }
    
    // MARK: - Segment Interpolation
    
    private func interpolateSegments(
        route: MKRoute,
        mode: TravelMode,
        departureTime: Date
    ) async throws -> [WizPathSegment] {
        let polyline = route.polyline
        let points = polyline.points()
        let pointCount = polyline.pointCount
        
        let totalDuration = route.expectedTravelTime
        let segmentInterval = mode.segmentInterval
        let numSegments = max(2, Int(totalDuration / segmentInterval))
        
        var segments: [WizPathSegment] = []
        
        // Always include start point
        let startSegment = WizPathSegment(
            id: UUID(),
            coordinate: points[0].coordinate,
            estimatedArrival: departureTime,
            distanceFromStart: 0,
            travelTime: 0,
            weather: nil
        )
        segments.append(startSegment)
        
        // Interpolate points along route based on time
        for i in 1..<numSegments {
            let progress = Double(i) / Double(numSegments - 1)
            let travelTime = totalDuration * progress
            let estimatedArrival = departureTime.addingTimeInterval(travelTime)
            
            // Find coordinate at this time progress
            let pointIndex = min(Int(Double(pointCount - 1) * progress), pointCount - 1)
            let coordinate = points[pointIndex].coordinate
            
            // Calculate distance (approximate from polyline)
            let distance = route.distance * progress
            
            let segment = WizPathSegment(
                id: UUID(),
                coordinate: coordinate,
                estimatedArrival: estimatedArrival,
                distanceFromStart: distance,
                travelTime: travelTime,
                weather: nil
            )
            segments.append(segment)
        }
        
        return segments
    }
    
    // MARK: - Weather Fetching (Throttled)
    
    private func fetchWeatherForSegments(
        _ segments: [WizPathSegment]
    ) async throws -> [WizPathSegment] {
        // Throttle to max 5 concurrent requests
        let batchSize = 5
        var updatedSegments = segments
        
        for batchStart in stride(from: 0, to: segments.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, segments.count)
            let batchIndices = batchStart..<batchEnd
            
            // Fetch weather for this batch concurrently
            try await withThrowingTaskGroup(of: (Int, SegmentWeather?).self) { group in
                for index in batchIndices {
                    let segment = segments[index]
                    
                    group.addTask {
                        do {
                            // Check cache first
                            if let cached = self.cache.weather(for: segment.coordinate, at: segment.estimatedArrival) {
                                return (index, cached)
                            }
                            
                            // Fetch from API
                            let weather = try await self.weatherService.fetchWeather(
                                coordinate: segment.coordinate,
                                time: segment.estimatedArrival
                            )
                            
                            // Cache the result
                            self.cache.store(weather: weather, for: segment.coordinate, at: segment.estimatedArrival)
                            
                            return (index, weather)
                        } catch {
                            AppLogger.weather.error("Failed to fetch weather for segment \(index): \(error)")
                            return (index, nil)
                        }
                    }
                }
                
                // Collect results
                for try await (index, weather) in group {
                    if let weather = weather {
                        updatedSegments[index].weather = weather
                    }
                }
            }
            
            // Small delay between batches to avoid rate limiting
            if batchEnd < segments.count {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
        
        return updatedSegments
    }
    
    // MARK: - Traffic Update
    
    /// Recalculate route with current traffic conditions
    func updateWithCurrentTraffic() async {
        guard let currentRoute = currentRoute else { return }
        
        do {
            let updatedRoute = try await calculateRoute(
                origin: currentRoute.origin,
                destination: currentRoute.destination,
                mode: currentRoute.travelMode,
                departureTime: Date() // Now
            )
            
            self.currentRoute = updatedRoute
        } catch {
            AppLogger.wizPath.error("Failed to update with traffic: \(error)")
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapMKError(_ error: Error) -> WizPathError {
        let nsError = error as NSError
        
        switch nsError.code {
        case 1: // Directions not found
            return .routeUnavailable
        case 2: // Network error
            return .weatherAPIFailed
        default:
            return .routeUnavailable
        }
    }
    
    // MARK: - Weather Safety Score
    
    /// Calculate safety score for a route
    func calculateSafetyScore(for route: WizPathRoute) -> RouteSafetyScore {
        let segments = route.segments
        
        // Calculate weather score (0-40 points)
        let weatherScore = calculateWeatherScore(segments: segments)
        
        // Calculate hazard score (0-40 points)
        let hazards = WizPathHazardService.shared.detectHazards(along: route)
        let hazardScore = max(0, 40 - (hazards.count * 10))
        
        // Calculate POI score (0-20 points)
        let poiScore = calculatePOIScore(segments: segments)
        
        // Overall score
        let overallScore = min(100, weatherScore + hazardScore + poiScore)
        
        // Count hazards by severity
        let criticalHazards = hazards.filter { $0.severity == .critical }.count
        let highHazards = hazards.filter { $0.severity == .high }.count
        
        return RouteSafetyScore(
            overallScore: overallScore,
            weatherScore: weatherScore,
            hazardScore: hazardScore,
            poiScore: poiScore,
            hazardCount: hazards.count,
            safeStopCount: 0, // Will be populated by POI service
            unsafeStopCount: 0, // Will be populated by POI service
            recommendedAlternatives: [] // Will be populated by route comparison
        )
    }
    
    private func calculateWeatherScore(segments: [WizPathSegment]) -> Int {
        guard !segments.isEmpty else { return 0 }
        
        let totalSegments = segments.count
        var goodWeatherCount = 0
        var fairWeatherCount = 0
        var cautionWeatherCount = 0
        var severeWeatherCount = 0
        
        for segment in segments {
            guard let weather = segment.weather else {
                cautionWeatherCount += 1
                continue
            }
            
            switch weather.severity {
            case .good: goodWeatherCount += 1
            case .fair: fairWeatherCount += 1
            case .caution: cautionWeatherCount += 1
            case .severe: severeWeatherCount += 1
            }
        }
        
        // Score calculation
        // Good: 1.0, Fair: 0.8, Caution: 0.4, Severe: 0.0
        let weightedScore = Double(goodWeatherCount) * 1.0 +
                           Double(fairWeatherCount) * 0.8 +
                           Double(cautionWeatherCount) * 0.4 +
                           Double(severeWeatherCount) * 0.0
        
        let normalizedScore = weightedScore / Double(totalSegments)
        return Int(normalizedScore * 40) // Max 40 points for weather
    }
    
    private func calculatePOIScore(segments: [WizPathSegment]) -> Int {
        // Check if there are safe stops along the route
        // This is simplified - in production, check actual POI availability
        let hasSafeConditions = segments.contains { segment in
            segment.weather?.severity == .good || segment.weather?.severity == .fair
        }
        
        return hasSafeConditions ? 20 : 10
    }
    
    // MARK: - Alternate Route Comparison
    
    /// Compare multiple routes and find the safest one
    func compareRoutes(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TravelMode,
        departureTime: Date
    ) async -> RouteComparisonResult {
        do {
            // Get alternate routes
            let routes = try await calculateAlternateRoutes(
                origin: origin,
                destination: destination,
                mode: mode,
                departureTime: departureTime
            )
            
            // Calculate safety scores for each
            var scoredRoutes: [(route: WizPathRoute, score: RouteSafetyScore)] = []
            for route in routes {
                let score = calculateSafetyScore(for: route)
                scoredRoutes.append((route, score))
            }
            
            // Sort by overall score (descending)
            scoredRoutes.sort { $0.score.overallScore > $1.score.overallScore }
            
            guard let bestRoute = scoredRoutes.first else {
                throw WizPathError.routeUnavailable
            }
            
            // Find recommended alternative if fastest route is unsafe
            var recommendedAlternative: WizPathRoute? = nil
            var timeDifference: TimeInterval? = nil
            
            if bestRoute.score.overallScore < 60, scoredRoutes.count > 1 {
                // Find a safer alternative
                for i in 1..<scoredRoutes.count {
                    let alternative = scoredRoutes[i]
                    if alternative.score.overallScore >= 70 {
                        recommendedAlternative = alternative.route
                        timeDifference = alternative.route.totalDuration - bestRoute.route.totalDuration
                        break
                    }
                }
            }
            
            return RouteComparisonResult(
                fastestRoute: bestRoute.route,
                fastestScore: bestRoute.score,
                recommendedAlternative: recommendedAlternative,
                timeDifference: timeDifference,
                allRoutes: scoredRoutes.map { $0.route }
            )
            
        } catch {
            AppLogger.wizPath.error("Route comparison failed: \(error)")
            return RouteComparisonResult(
                fastestRoute: nil,
                fastestScore: nil,
                recommendedAlternative: nil,
                timeDifference: nil,
                allRoutes: []
            )
        }
    }
    
    private func calculateAlternateRoutes(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TravelMode,
        departureTime: Date
    ) async throws -> [WizPathRoute] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = mode.mkTransportType
        request.departureDate = departureTime
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        var routes: [WizPathRoute] = []
        
        for (index, mkRoute) in response.routes.enumerated() {
            // Calculate weather for each route
            let segments = try await interpolateSegments(
                route: mkRoute,
                mode: mode,
                departureTime: departureTime
            )
            
            let segmentsWithWeather = try await fetchWeatherForSegments(segments)
            
            let wizPathRoute = WizPathRoute(
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
            
            routes.append(wizPathRoute)
        }
        
        return routes
    }
}

// MARK: - Route Comparison Result
struct RouteComparisonResult: Sendable {
    let fastestRoute: WizPathRoute?
    let fastestScore: RouteSafetyScore?
    let recommendedAlternative: WizPathRoute?
    let timeDifference: TimeInterval?
    let allRoutes: [WizPathRoute]
    
    var shouldShowAlternative: Bool {
        guard let fastestScore = fastestScore,
              let timeDiff = timeDifference else { return false }
        
        // Show alternative if fastest route is risky and alternative adds < 30 mins
        return fastestScore.overallScore < 60 && timeDiff < 30 * 60
    }
    
    var alternativeMessage: String? {
        guard let timeDiff = timeDifference,
              let alternative = recommendedAlternative else { return nil }
        
        let minutes = Int(timeDiff) / 60
        let altScore = alternative.overallRisk
        
        return L10n.formatted("route_alternative_message", minutes, altScore.localizedTitle)
    }
}

// MARK: - Weather Service Protocol
protocol WeatherServiceProtocol {
    func fetchWeather(coordinate: CLLocationCoordinate2D, time: Date) async throws -> SegmentWeather
}

// MARK: - Weather Service Implementation
@MainActor
final class WizPathWeatherService: ObservableObject, WeatherServiceProtocol {
    static let shared = WizPathWeatherService()
    
    func fetchWeather(coordinate: CLLocationCoordinate2D, time: Date) async throws -> SegmentWeather {
        // Integration with existing weather service
        // This would call the existing ForeWiz weather API
        // For now, return mock data for the architecture
        
        // In production, this calls:
        // - WeatherKit for Apple-native
        // - OpenWeather API for 3rd party
        // - Existing ForeWiz weather service
        
        return SegmentWeather(
            condition: .clear,
            temperature: 22.0,
            precipitationChance: 0.1,
            windSpeed: 12.0,
            visibility: 10.0,
            severity: .good
        )
    }
}

// MARK: - API Throttle Manager
final class APIThrottleManager {
    private var lastRequestTime: Date = .distantPast
    private let minInterval: TimeInterval = 0.1 // 100ms between requests
    
    func throttle() async {
        let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
        if timeSinceLastRequest < minInterval {
            let waitTime = minInterval - timeSinceLastRequest
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
}

// MARK: - WizPath Cache
final class WizPathCache {
    static let shared = WizPathCache()
    
    private var routeCache: [String: WizPathRoute] = [:]
    private var weatherCache: [String: SegmentWeather] = [:]
    private let weatherTTL: TimeInterval = 15 * 60 // 15 minutes
    private var weatherTimestamps: [String: Date] = [:]
    
    private init() {}
    
    func store(route: WizPathRoute) {
        let key = cacheKey(origin: route.origin, destination: route.destination, mode: route.travelMode)
        routeCache[key] = route
    }
    
    func route(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, mode: TravelMode) -> WizPathRoute? {
        let key = cacheKey(origin: origin, destination: destination, mode: mode)
        return routeCache[key]
    }
    
    func store(weather: SegmentWeather, for coordinate: CLLocationCoordinate2D, at time: Date) {
        let key = weatherCacheKey(coordinate: coordinate, time: time)
        weatherCache[key] = weather
        weatherTimestamps[key] = Date()
    }
    
    func weather(for coordinate: CLLocationCoordinate2D, at time: Date) -> SegmentWeather? {
        let key = weatherCacheKey(coordinate: coordinate, time: time)
        
        // Check TTL
        if let timestamp = weatherTimestamps[key],
           Date().timeIntervalSince(timestamp) < weatherTTL {
            return weatherCache[key]
        }
        
        // Expired
        weatherCache.removeValue(forKey: key)
        weatherTimestamps.removeValue(forKey: key)
        return nil
    }
    
    private func cacheKey(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, mode: TravelMode) -> String {
        "\(origin.latitude),\(origin.longitude)|\(destination.latitude),\(destination.longitude)|\(mode.rawValue)"
    }
    
    private func weatherCacheKey(coordinate: CLLocationCoordinate2D, time: Date) -> String {
        // Round to nearest 15 minutes for caching
        let roundedTime = round(time.timeIntervalSince1970 / 900) * 900
        return "\(coordinate.latitude),\(coordinate.longitude)|\(roundedTime)"
    }
}
