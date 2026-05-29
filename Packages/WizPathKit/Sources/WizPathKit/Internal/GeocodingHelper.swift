import Foundation
import CoreLocation

// MARK: - Geocoding Cache (Actor for Swift 6 safety)

/// Thread-safe cache for reverse geocoding results using Swift actors.
private actor GeocodingCache {
    private var storage: [String: String] = [:]

    func value(forKey key: String) -> String? {
        storage[key]
    }

    func setValue(_ value: String, forKey key: String) {
        storage[key] = value
    }

    func clear() {
        storage.removeAll()
    }
}

// MARK: - Geocoding Helper

/// Reverse geocodes coordinates to human-readable place names with caching.
/// Uses an actor for thread-safe cache access, fully compliant with Swift 6 strict concurrency.
final class GeocodingHelper {
    nonisolated(unsafe) static let shared = GeocodingHelper()
    private let geocoder = CLGeocoder()
    private let cache = GeocodingCache()

    private init() {}

    /// Resolves a coordinate to a short, readable place name (e.g. "Kadıköy", "Bostancı")
    /// Returns `nil` if geocoding fails or times out.
    func resolvePlaceName(for coordinate: CLLocationCoordinate2D) async -> String? {
        let key = "\(coordinate.latitude),\(coordinate.longitude)"

        // Check cache first (actor-safe, async)
        if let cached = await cache.value(forKey: key) {
            return cached
        }

        // Wait for a rate-limit slot (shared across all PlaceRequest types)
        await PlaceRequestThrottler.shared.waitForSlot()

        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            let placeName: String? = extractPlaceName(from: placemarks)

            if let name = placeName {
                await cache.setValue(name, forKey: key)
            }
            return placeName
        } catch {
            AppLogger.wizPath.warning("Geocoding failed for (\(coordinate.latitude), \(coordinate.longitude)): \(error.localizedDescription)")
            return nil
        }
    }

    /// Resolves multiple coordinates sequentially (avoids Swift 6 `sending` closure issues).
    /// Since most lookups hit cache after first use and weather change points are few,
    /// sequential resolution is fast enough and keeps the code safe under strict concurrency.
    func resolvePlaceNames(for segments: [WizPathSegment]) async -> [UUID: String] {
        var results: [UUID: String] = [:]
        for segment in segments {
            if let name = await resolvePlaceName(for: segment.coordinate) {
                results[segment.id] = name
            }
        }
        return results
    }

    func clearCache() async {
        await cache.clear()
    }

    // MARK: - Helpers

    /// Extracts the most specific human-readable place name from placemarks.
    private func extractPlaceName(from placemarks: [CLPlacemark]) -> String? {
        guard let placemark = placemarks.first else { return nil }

        // Priority order:
        // 1. A named point of interest / street address
        // 2. Sub-locality (neighborhood, e.g. "Kadıköy", "Levent")
        // 3. Locality (city, e.g. "İstanbul")
        // 4. Sub-administrative area
        if let name = placemark.name,
           name != placemark.locality,
           name != placemark.subLocality,
           !name.isEmpty {
            return name
        }
        if let subLocality = placemark.subLocality, !subLocality.isEmpty {
            return subLocality
        }
        if let locality = placemark.locality, !locality.isEmpty {
            return locality
        }
        if let subAdmin = placemark.subAdministrativeArea, !subAdmin.isEmpty {
            return subAdmin
        }
        return nil
    }
}
