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

        return Array(deduplicated(stops)
            .sorted {
                if $0.distanceFromRoute == $1.distanceFromRoute {
                    return $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
                }
                return $0.distanceFromRoute < $1.distanceFromRoute
            }
            .prefix(12))
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
}
