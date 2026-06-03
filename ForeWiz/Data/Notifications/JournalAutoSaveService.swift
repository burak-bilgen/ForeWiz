import Foundation
import CoreLocation
import OSLog
import MapKit
import WizPathKit

/// Observes route completion events and auto-saves journal entries.
/// Captures route snapshot, weather conditions, and health data at the time of the trip.
final class JournalAutoSaveService {
    private let journalStore: JournalStore

    init(journalStore: JournalStore) {
        self.journalStore = journalStore
    }

    func onRouteCompleted(
        route: WizPathRoute,
        destinationName: String,
        mode: TravelMode
    ) async {
        let entry = buildJournalEntry(route: route, destinationName: destinationName, mode: mode)
        do {
            try await journalStore.save(entry)
            AppLogger.app.info("Journal entry auto-saved for trip to \(destinationName)")
        } catch {
            AppLogger.app.error("Failed to auto-save journal entry: \(error.localizedDescription)")
        }
    }

    // MARK: - Entry Builder

    private func buildJournalEntry(
        route: WizPathRoute,
        destinationName: String,
        mode: TravelMode
    ) -> JournalEntry {
        let originName = "Origin"
        let now = Date()
        let hudData = route.journeyHUDData()
        let polylineCoords = extractPolylineCoords(route.polyline)

        let routeData = try? JSONEncoder().encode(
            RouteSnapshot(
                originName: originName,
                destinationName: destinationName,
                travelModeRaw: mode.rawValue,
                totalDuration: route.totalDuration,
                totalDistance: route.totalDistance,
                safetyScore: hudData.safetyScore,
                hazardCount: hudData.hazardCount,
                routePolyline: polylineCoords
            )
        )

        let title: String = {
            if Calendar.current.isDateInToday(now) {
                return "Trip to \(destinationName)"
            } else {
                return "Trip to \(destinationName) — \(now.formatted(date: .abbreviated, time: .omitted))"
            }
        }()

        return JournalEntry(
            id: UUID(),
            date: now,
            title: title,
            locationName: destinationName,
            latitude: route.destination.latitude,
            longitude: route.destination.longitude,
            weatherSnapshotData: nil,
            routeData: routeData,
            healthData: nil,
            notes: nil,
            createdAt: now,
            typeRaw: "trip"
        )
    }

    /// Extracts coordinate pairs from an MKPolyline for storage.
    private func extractPolylineCoords(_ polyline: MKPolyline?) -> [[Double]] {
        guard let polyline = polyline else { return [] }
        let points = polyline.points()
        let count = min(polyline.pointCount, 50) // Limit to 50 points for storage
        var coords: [[Double]] = []
        let step = max(1, polyline.pointCount / count)
        var idx = 0
        while idx < polyline.pointCount {
            let coord = points[idx].coordinate
            coords.append([coord.latitude, coord.longitude])
            idx += step
        }
        return coords
    }
}

// MARK: - RouteSnapshot

struct RouteSnapshot: Codable, Equatable, Sendable {
    let originName: String
    let destinationName: String
    let travelModeRaw: String
    let totalDuration: TimeInterval
    let totalDistance: Double
    let safetyScore: Int
    let hazardCount: Int
    let routePolyline: [[Double]]
}
