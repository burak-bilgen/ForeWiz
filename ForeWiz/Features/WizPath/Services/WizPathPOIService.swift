import Foundation
import CoreLocation
@preconcurrency import MapKit
import OSLog

// MARK: - POI Service
@MainActor
final class WizPathPOIService {
    static let shared = WizPathPOIService()
    
    private init() {}
    
    // MARK: - Smart POI Search
    
    /// Search for POIs along the route with weather intersection
    func findSmartStops(
        along route: WizPathRoute,
        categories: [POICategory] = [.gasStation, .evCharger],
        maxResults: Int = 10
    ) async -> [SmartStop] {
        var allStops: [SmartStop] = []
        
        // Search for each category
        for category in categories {
            let pois = await searchPOIs(
                along: route,
                category: category,
                maxResults: maxResults / categories.count
            )
            
            // Intersect with weather data
            let smartStops = pois.map { poi in
                createSmartStop(
                    from: poi,
                    along: route
                )
            }
            
            allStops.append(contentsOf: smartStops)
        }
        
        // Sort by safety (safe first), then by distance from route
        return allStops.sorted { lhs, rhs in
            if lhs.safetyStatus.shouldAvoid != rhs.safetyStatus.shouldAvoid {
                return !lhs.safetyStatus.shouldAvoid
            }
            return lhs.distanceFromRoute < rhs.distanceFromRoute
        }
    }
    
    // MARK: - MKLocalSearch Integration
    
    private func searchPOIs(
        along route: WizPathRoute,
        category: POICategory,
        maxResults: Int
    ) async -> [MKMapItem] {
        // Create a polygon around the route
        guard let routePolyline = route.polyline else { return [] }
        
        let pointCount = routePolyline.pointCount
        guard pointCount > 0 else { return [] }
        
        let routePoints = routePolyline.points()
        
        // Sample points along route for search (every 30 mins)
        let searchInterval: TimeInterval = 30 * 60 // 30 minutes
        let searchPoints = samplePointsAlongRoute(route, interval: searchInterval)
        
        var allPOIs: [MKMapItem] = []
        var seenIdentifiers = Set<String>()
        
        // Search around each sampled point
        for point in searchPoints {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = category == .gasStation ? "gas station" : "EV charger"
            request.region = MKCoordinateRegion(
                center: point,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            request.resultTypes = .pointOfInterest
            
            let search = MKLocalSearch(request: request)
            
            do {
                let response = try await search.start()
                
                for mapItem in response.mapItems {
                    // Check if we've already seen this POI
                    let identifier = "\(mapItem.placemark.coordinate.latitude),\(mapItem.placemark.coordinate.longitude)"
                    if seenIdentifiers.contains(identifier) {
                        continue
                    }
                    seenIdentifiers.insert(identifier)
                    
                    // Check if POI is actually near the route
                    let distance = distanceFromRoute(mapItem.placemark.coordinate, route: route)
                    if distance < 5000 { // Within 5km of route
                        allPOIs.append(mapItem)
                    }
                }
            } catch {
                AppLogger.wizPath.error("POI search failed: \(error)")
            }
        }
        
        // Sort by distance from route and take best results
        let sortedPOIs = allPOIs.sorted { lhs, rhs in
            let distL = distanceFromRoute(lhs.placemark.coordinate, route: route)
            let distR = distanceFromRoute(rhs.placemark.coordinate, route: route)
            return distL < distR
        }
        
        return Array(sortedPOIs.prefix(maxResults))
    }
    
    // MARK: - Smart Stop Creation
    
    private func createSmartStop(
        from mapItem: MKMapItem,
        along route: WizPathRoute
    ) -> SmartStop {
        let coordinate = mapItem.placemark.coordinate
        let name = mapItem.name ?? ""
        
        // Determine category
        let category: POICategory
        if name.lowercased().contains("tesla") || 
           name.lowercased().contains("charger") ||
           name.lowercased().contains("ev") {
            category = .evCharger
        } else if name.lowercased().contains("rest") ||
                  name.lowercased().contains("sleep") {
            category = .restStop
        } else {
            category = .gasStation
        }
        
        // Calculate ETA at this POI
        let distanceFromStart = distanceAlongRoute(to: coordinate, route: route)
        let avgSpeed = route.totalDistance / route.totalDuration
        let travelTime = distanceFromStart / max(avgSpeed, 1)
        let eta = route.departureTime.addingTimeInterval(travelTime)
        
        // Find weather at this ETA
        let weather = interpolateWeather(at: eta, along: route)
        
        // Determine safety status
        let safetyStatus = assessPOISafety(weather: weather, category: category)
        
        // Calculate distance from route
        let distanceFromRoute = self.distanceFromRoute(coordinate, route: route)
        
        // Estimate stop duration
        let stopDuration: TimeInterval
        switch category {
        case .gasStation: stopDuration = 10 * 60 // 10 minutes
        case .evCharger: stopDuration = 30 * 60 // 30 minutes
        case .restStop: stopDuration = 20 * 60 // 20 minutes
        case .restaurant: stopDuration = 45 * 60 // 45 minutes
        }
        
        return SmartStop(
            id: UUID(),
            mapItem: mapItem,
            coordinate: coordinate,
            name: name,
            category: category,
            etaArrival: eta,
            weatherAtArrival: weather,
            safetyStatus: safetyStatus,
            distanceFromRoute: distanceFromRoute,
            estimatedStopDuration: stopDuration
        )
    }
    
    // MARK: - Safety Assessment
    
    private func assessPOISafety(weather: SegmentWeather?, category: POICategory) -> POISafetyStatus {
        guard let weather = weather else {
            return .caution // Unknown weather, be cautious
        }
        
        // EV Chargers are especially dangerous in thunderstorms
        if category == .evCharger {
            if weather.condition == .thunderstorm {
                return .dangerous
            }
            if weather.condition == .heavyRain {
                return .unsafe
            }
        }
        
        // Gas stations also risky in storms
        if weather.condition == .thunderstorm {
            return .unsafe
        }
        
        // General weather assessment
        switch weather.severity {
        case .good: return .safe
        case .fair: return .safe
        case .caution: return .caution
        case .severe: return .unsafe
        }
    }
    
    // MARK: - Helpers
    
    private func samplePointsAlongRoute(_ route: WizPathRoute, interval: TimeInterval) -> [CLLocationCoordinate2D] {
        guard let polyline = route.polyline else { return [] }
        
        let pointCount = polyline.pointCount
        guard pointCount > 0 else { return [] }
        
        let points = polyline.points()
        
        var sampledPoints: [CLLocationCoordinate2D] = []
        let totalDuration = route.totalDuration
        let numSamples = max(2, Int(totalDuration / interval))
        
        for i in 0..<numSamples {
            let progress = Double(i) / Double(numSamples - 1)
            let pointIndex = min(Int(Double(pointCount - 1) * progress), pointCount - 1)
            sampledPoints.append(points[pointIndex].coordinate)
        }
        
        return sampledPoints
    }
    
    private func distanceFromRoute(_ coordinate: CLLocationCoordinate2D, route: WizPathRoute) -> CLLocationDistance {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Find closest point on route polyline
        guard let polyline = route.polyline else { return .greatestFiniteMagnitude }
        
        let pointCount = polyline.pointCount
        guard pointCount > 0 else { return .greatestFiniteMagnitude }
        
        let points = polyline.points()
        
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude
        
        for i in 0..<pointCount {
            let point = points[i]
            let pointLocation = CLLocation(
                latitude: point.coordinate.latitude,
                longitude: point.coordinate.longitude
            )
            let distance = location.distance(from: pointLocation)
            minDistance = min(minDistance, distance)
        }
        
        return minDistance
    }
    
    private func distanceAlongRoute(to coordinate: CLLocationCoordinate2D, route: WizPathRoute) -> CLLocationDistance {
        // Approximate distance along route to the closest point
        guard let polyline = route.polyline else { return 0 }
        
        let pointCount = polyline.pointCount
        guard pointCount > 0 else { return 0 }
        
        let points = polyline.points()
        
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Find closest point index
        var closestIndex = 0
        var minDistance = Double.greatestFiniteMagnitude
        
        for index in 0..<pointCount {
            let point = points[index]
            let pointLocation = CLLocation(
                latitude: point.coordinate.latitude,
                longitude: point.coordinate.longitude
            )
            let distance = targetLocation.distance(from: pointLocation)
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        
        // Calculate cumulative distance to that point
        var cumulativeDistance: CLLocationDistance = 0
        for i in 1...closestIndex {
            let prevPoint = points[i-1]
            let currPoint = points[i]
            let prevLocation = CLLocation(
                latitude: prevPoint.coordinate.latitude,
                longitude: prevPoint.coordinate.longitude
            )
            let currLocation = CLLocation(
                latitude: currPoint.coordinate.latitude,
                longitude: currPoint.coordinate.longitude
            )
            cumulativeDistance += prevLocation.distance(from: currLocation)
        }
        
        return cumulativeDistance
    }
    
    private func interpolateWeather(at time: Date, along route: WizPathRoute) -> SegmentWeather? {
        // Find the two segments bracketing this time and interpolate
        let segments = route.segments
        
        // Find closest segment
        var closestSegment: WizPathSegment?
        var minTimeDiff: TimeInterval = .greatestFiniteMagnitude
        
        for segment in segments {
            let timeDiff = abs(segment.estimatedArrival.timeIntervalSince(time))
            if timeDiff < minTimeDiff {
                minTimeDiff = timeDiff
                closestSegment = segment
            }
        }
        
        return closestSegment?.weather
    }
}
