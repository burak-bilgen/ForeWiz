import Foundation
@preconcurrency import MapKit
import CoreLocation

// MARK: - POI Search Service

public final class POISearchService: Sendable {
    public static let shared = POISearchService()
    private init() {}

    public func searchSmartStopsAlongRoute(route: WizPathRoute, categories: [POICategory], radius: CLLocationDistance = 10_000) async -> [SmartStop] {
        let routeCoordinates = route.routeCoordinates
        guard !routeCoordinates.isEmpty, !categories.isEmpty else { return [] }

        var stops: [SmartStop] = []
        for coordinate in searchCoordinates(from: routeCoordinates) {
            for category in categories {
                guard !Task.isCancelled else { return [] }

                let request = MKLocalSearch.Request()
                switch category {
                case .evCharger:
                    request.naturalLanguageQuery = "EV charger"
                    request.pointOfInterestFilter = .init(including: [.evCharger])
                case .gasStation:
                    request.naturalLanguageQuery = "Gas station"
                    request.pointOfInterestFilter = .init(including: [.gasStation])
                case .restStop:
                    request.naturalLanguageQuery = "Rest area"
                    request.pointOfInterestFilter = .init(excluding: [])
                case .restaurant:
                    request.naturalLanguageQuery = "Restaurant"
                    request.pointOfInterestFilter = .init(including: [.restaurant, .cafe])
                }

                request.resultTypes = .pointOfInterest
                request.region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: radius,
                    longitudinalMeters: radius
                )
                stops.append(contentsOf: await executeSearch(request, category: category, routeCoordinates: routeCoordinates))
            }
        }

        let dedupped = deduplicated(stops)
        
        // Compute premium niche scores and sort descending
        let scoredStops = dedupped.map { stop -> (stop: SmartStop, score: Double) in
            return (stop, self.calculateNicheScore(for: stop))
        }.sorted { $0.score > $1.score }
        
        // Apply spatial spacing filter to prevent recommendation clustering (e.g. 10 gas stations in a row)
        let minSpacing = max(8_000, min(25_000, route.totalDistance / 6))
        var acceptedStops: [SmartStop] = []
        
        for item in scoredStops {
            let stop = item.stop
            // Check if there is an accepted stop of the same category that is too close
            let tooClose = acceptedStops.contains { accepted in
                accepted.category == stop.category &&
                self.coordinateDistance(accepted.coordinate, stop.coordinate) < minSpacing
            }
            if !tooClose {
                acceptedStops.append(stop)
            }
        }
        
        return Array(acceptedStops.prefix(12))
    }

    public func searchChargersAlongRoute(route: WizPathRoute, radius: CLLocationDistance = 10_000) async -> [SmartStop] {
        await searchSmartStopsAlongRoute(route: route, categories: [.evCharger], radius: radius)
    }

    private func executeSearch(_ request: MKLocalSearch.Request, category: POICategory, routeCoordinates: [CLLocationCoordinate2D]) async -> [SmartStop] {
        let search = MKLocalSearch(request: request)
        return await withCheckedContinuation { continuation in
            search.start { response, error in
                guard let response = response, error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                let stops = response.mapItems.compactMap { mapItem -> SmartStop? in
                    guard let coordinate = mapItem.placemark.location?.coordinate else { return nil }
                    let distanceFromRoute = self.distanceFromRoute(coordinate, routeCoordinates: routeCoordinates)
                    return SmartStop(
                        id: UUID(),
                        mapItem: mapItem,
                        coordinate: coordinate,
                        name: mapItem.name ?? category.defaultName,
                        category: category,
                        etaArrival: Date(),
                        weatherAtArrival: nil,
                        safetyStatus: .safe,
                        distanceFromRoute: distanceFromRoute,
                        estimatedStopDuration: 1800
                    )
                }
                continuation.resume(returning: stops)
            }
        }
    }

    private func searchCoordinates(from routeCoordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        guard routeCoordinates.count > 1 else { return routeCoordinates }

        let lastIndex = routeCoordinates.count - 1
        let indices = Set([
            0,
            routeCoordinates.count / 4,
            routeCoordinates.count / 2,
            (routeCoordinates.count * 3) / 4,
            lastIndex
        ])

        return indices.sorted().map { routeCoordinates[$0] }
    }

    private func deduplicated(_ stops: [SmartStop]) -> [SmartStop] {
        var seen: Set<String> = []
        return stops.filter { stop in
            let key = "\(stop.displayTitle.lowercased())-\(coordinateKey(stop.coordinate))"
            return seen.insert(key).inserted
        }
    }

    private func coordinateKey(_ coordinate: CLLocationCoordinate2D) -> String {
        let latitude = Int((coordinate.latitude * 10_000).rounded())
        let longitude = Int((coordinate.longitude * 10_000).rounded())
        return "\(latitude):\(longitude)"
    }

    private func distanceFromRoute(_ coordinate: CLLocationCoordinate2D, routeCoordinates: [CLLocationCoordinate2D]) -> CLLocationDistance {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return routeCoordinates
            .map { location.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) }
            .min() ?? 0
    }

    private func calculateNicheScore(for stop: SmartStop) -> Double {
        var score = 100.0
        
        // Website adds points (high quality, premium niche stop)
        if stop.mapItem.url != nil {
            score += 30.0
        }
        
        // Phone number adds points (verified establishment)
        if stop.mapItem.phoneNumber != nil {
            score += 15.0
        }
        
        // Distance penalty: -1 point per 200 meters from the route
        let distPenalty = stop.distanceFromRoute / 200.0
        score -= distPenalty
        
        // Check if the place has a generic, boring name (like generic "Gas", "Station", "Petrol")
        let nameLower = stop.name.lowercased()
        let hasGenericName = nameLower.contains("gas") || nameLower.contains("station") || nameLower.contains("petrol") || nameLower.contains("benzin") || nameLower.contains("otogaz") || nameLower.contains("istasyonu")
        
        if hasGenericName {
            score -= 20.0
        } else {
            // Unique/Niche named places get a boost
            score += 20.0
        }
        
        // Category preference: restaurants/cafes and rest stops are more "niche/comfort" than generic gas stations
        if stop.category == .restaurant || stop.category == .restStop {
            score += 15.0
        }
        
        return score
    }

    private func coordinateDistance(_ c1: CLLocationCoordinate2D, _ c2: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: c1.latitude, longitude: c1.longitude)
        let loc2 = CLLocation(latitude: c2.latitude, longitude: c2.longitude)
        return loc1.distance(from: loc2)
    }
}
