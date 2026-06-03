import Foundation
import CoreLocation

/// Encodable route data stored in JournalEntry.routeData.
/// Used for deduplication and display in Journal UI.
struct JournalRouteData: Codable, Equatable {
    let originLat: Double
    let originLng: Double
    let destLat: Double
    let destLng: Double
    let travelMode: String
    let totalDuration: TimeInterval
    let totalDistance: CLLocationDistance
    let departureTime: Date
    let segmentCount: Int
}

/// Encodable weather snapshot stored in JournalEntry.weatherSnapshotData.
struct JournalWeatherSnapshot: Codable, Equatable {
    let temperature: Double
    let condition: String
    let windSpeed: Double
    let precipitationChance: Double
    let severity: String
}
