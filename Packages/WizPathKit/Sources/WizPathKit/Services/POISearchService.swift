import Foundation
@preconcurrency import MapKit
import CoreLocation

// MARK: - POI Search Service

public final class POISearchService: Sendable {
    public static let shared = POISearchService()

    // Basit in-memory cache: hash → [SmartStop]
    private let cache = POISearchCache()

    private init() {}

    /// Rota boyunca akıllı durak (POI) araması yapar.
    /// - Parameters:
    ///   - route: Analiz edilecek rota.
    ///   - categories: Aranacak POI kategorileri.
    ///   - radius: Her arama noktası etrafındaki tarama yarıçapı (metre).
    ///   - maxRouteDeviation: Rotadan maksimum sapma (metre) — bundan uzak POI'lar filtrelenir.
    ///   - forceRefresh: `true` ise cache'i atlayıp yeni arama yapar.
    public func searchSmartStopsAlongRoute(
        route: WizPathRoute,
        categories: [POICategory],
        radius: CLLocationDistance = 10_000,
        maxRouteDeviation: CLLocationDistance = 2_000,
        forceRefresh: Bool = false
    ) async -> [SmartStop] {
        let routeCoordinates = route.routeCoordinates
        guard !routeCoordinates.isEmpty, !categories.isEmpty else { return [] }

        // Cache key: origin + destination + travel mode + kategoriler + radius + geometry hash
        // We include a dynamic geometry hash (coordinate count and total distance) so that detours
        // (such as when avoidTollRoads is toggled) automatically bypass the cache and refresh stops.
        let og = route.origin
        let dst = route.destination
        let geometryHash = "\(routeCoordinates.count)-\(Int(route.totalDistance))"
        let cacheKey = "\(og.latitude),\(og.longitude)|\(dst.latitude),\(dst.longitude)|\(route.travelMode.rawValue)|\(categories.map(\.rawValue).sorted().joined()):\(Int(radius))|\(geometryHash)"
        if !forceRefresh, let cached = cache.retrieve(key: cacheKey) {
            return cached
        }

        let searchPoints = searchCoordinates(from: routeCoordinates)

        var stops: [SmartStop] = []
        for coordinate in searchPoints {
            for category in categories {
                guard !Task.isCancelled else { return [] }

                let request = MKLocalSearch.Request()
                switch category {
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
                stops.append(contentsOf: await executeSearch(
                    request, category: category, routeCoordinates: routeCoordinates,
                    maxRouteDeviation: maxRouteDeviation
                ))
            }
        }

        let dedupped = deduplicated(stops)

        // Skorla ve sırala
        let scoredStops = dedupped.map { stop -> (stop: SmartStop, score: Double) in
            (stop, self.calculateNicheScore(for: stop))
        }.sorted { $0.score > $1.score }

        // Mesafe filtresi: aynı kategorideki duraklar arasında minimum boşluk bırak
        let segmentCount = max(1, route.segments.count)
        let avgSegmentDistanceKm = route.totalDistance / Double(segmentCount) / 1000.0
        let minSpacing: CLLocationDistance
        if avgSegmentDistanceKm > 5 {
            // Otoyol/kırsal: seyrek duraklar
            minSpacing = max(10_000, min(30_000, route.totalDistance / 5))
        } else {
            // Şehir içi: daha sık durak
            minSpacing = max(3_000, min(15_000, route.totalDistance / 8))
        }

        var acceptedStops: [SmartStop] = []
        for item in scoredStops {
            let stop = item.stop
            let tooClose = acceptedStops.contains { accepted in
                accepted.category == stop.category &&
                self.coordinateDistance(accepted.coordinate, stop.coordinate) < minSpacing
            }
            if !tooClose {
                acceptedStops.append(stop)
            }
        }

        let result = Array(acceptedStops.prefix(12))

        // Cache'e kaydet (5 dakika TTL)
        cache.store(key: cacheKey, stops: result, ttl: 300)

        return result
    }

    /// Cache'i temizle — kullanıcı manuel yenileme yaparsa çağrılabilir.
    public func clearCache() {
        cache.clear()
    }

    // MARK: - MKLocalSearch

    private func executeSearch(
        _ request: MKLocalSearch.Request,
        category: POICategory,
        routeCoordinates: [CLLocationCoordinate2D],
        maxRouteDeviation: CLLocationDistance
    ) async -> [SmartStop] {
        let search = MKLocalSearch(request: request)
        // 1. MKLocalSearch sonuçlarını bekle (sync callback → async continuation)
        let mapItems: [MKMapItem] = await withCheckedContinuation { continuation in
            search.start { response, error in
                guard let response = response, error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: response.mapItems)
            }
        }

        guard !mapItems.isEmpty else { return [] }

        // 2. Temel SmartStop'ları oluştur (sync — mesafe filtresi + statik alanlar)
        var preliminaryStops: [SmartStop] = []
        for mapItem in mapItems {
            guard let coordinate = mapItem.placemark.location?.coordinate else { continue }
            let distanceFromRoute = self.distanceFromRoute(coordinate, routeCoordinates: routeCoordinates)
            guard distanceFromRoute <= maxRouteDeviation else { continue }

            let stop = SmartStop(
                id: UUID(),
                mapItem: mapItem,
                coordinate: coordinate,
                name: mapItem.name ?? category.defaultName,
                category: category,
                etaArrival: Date(),
                weatherAtArrival: nil,
                safetyStatus: .safe,
                distanceFromRoute: distanceFromRoute,
                estimatedStopDuration: 1800,
                phoneNumber: mapItem.phoneNumber,
                url: mapItem.url
            )
            preliminaryStops.append(stop)
        }

        return preliminaryStops
    }

    // MARK: - Search Coordinate Sampling

    /// Rota koordinatlarından mesafe bazlı akıllı örnekleme yapar.
    /// Apple Maps rate limitlerini aşmamak için Origin, Midpoint ve Destination olarak tam 3 nokta seçer.
    private func searchCoordinates(from routeCoordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        let count = routeCoordinates.count
        guard count > 1 else { return routeCoordinates }
        
        var points: [CLLocationCoordinate2D] = []
        points.append(routeCoordinates[0]) // Origin
        if count > 2 {
            points.append(routeCoordinates[count / 2]) // Midpoint
        }
        points.append(routeCoordinates[count - 1]) // Destination
        return points
    }

    // MARK: - Deduplication

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

    // MARK: - Distance Helpers

    private func distanceFromRoute(_ coordinate: CLLocationCoordinate2D, routeCoordinates: [CLLocationCoordinate2D]) -> CLLocationDistance {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return routeCoordinates
            .map { location.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) }
            .min() ?? 0
    }

    private func coordinateDistance(_ c1: CLLocationCoordinate2D, _ c2: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: c1.latitude, longitude: c1.longitude)
        let loc2 = CLLocation(latitude: c2.latitude, longitude: c2.longitude)
        return loc1.distance(from: loc2)
    }

    // MARK: - Niche Scoring

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

        // Generic/niche name detection
        let nameLower = stop.name.lowercased()
        let hasGenericName = nameLower.contains("gas") || nameLower.contains("station") || nameLower.contains("petrol") || nameLower.contains("benzin") || nameLower.contains("otogaz") || nameLower.contains("istasyonu")

        if hasGenericName {
            score -= 20.0
        } else {
            score += 20.0
        }

        // Category preference
        if stop.category == .restaurant || stop.category == .restStop {
            score += 15.0
        }

        return max(0, score)
    }
}

// MARK: - POI Search Cache

private final class POISearchCache: @unchecked Sendable {
    private var cache: [String: CacheEntry] = [:]
    private let lock = NSLock()

    private struct CacheEntry {
        let stops: [SmartStop]
        let timestamp: Date
        let ttl: TimeInterval
        var isExpired: Bool { Date().timeIntervalSince(timestamp) > ttl }
    }

    func retrieve(key: String) -> [SmartStop]? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = cache[key], !entry.isExpired else {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.stops
    }

    func store(key: String, stops: [SmartStop], ttl: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        cache[key] = CacheEntry(stops: stops, timestamp: Date(), ttl: ttl)
        // Periyodik temizlik: 30'dan fazla giriş varsa süresi dolanları temizle
        if cache.count > 30 {
            cache = cache.filter { !$0.value.isExpired }
        }
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}
