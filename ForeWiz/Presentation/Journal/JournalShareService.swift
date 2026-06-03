import SwiftUI
import CoreLocation
import WizPathKit

final class JournalShareService {
    enum ShareError: LocalizedError {
        case renderFailed
        case noRouteData

        var errorDescription: String? {
            switch self {
            case .renderFailed: return "Could not generate shareable image."
            case .noRouteData: return "No route data to share."
            }
        }
    }

    @MainActor
    func generateShareImage(for entry: JournalEntry) async throws -> UIImage {
        let routeSnapshot: RouteSnapshot? = entry.routeData.flatMap { data in
            try? JSONDecoder().decode(RouteSnapshot.self, from: data)
        }

        let cardView = JournalShareCard(entry: entry, routeSnapshot: routeSnapshot)
            .frame(width: 400, height: 500)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = UIScreen.main.scale

        guard let image = renderer.uiImage else {
            throw ShareError.renderFailed
        }
        return image
    }

    func generateTextSummary(for entry: JournalEntry) -> String {
        var parts: [String] = []
        parts.append("📍 \(entry.title)")
        parts.append("📅 \(entry.date.formatted(date: .long, time: .shortened))")
        if let location = entry.locationName { parts.append("🗺️ \(location)") }
        if let routeData = entry.routeData,
           let route = try? JSONDecoder().decode(RouteSnapshot.self, from: routeData) {
            let duration = formatDuration(route.totalDuration)
            let distance = formatDistance(route.totalDistance)
            parts.append("🚗 \(duration) • \(distance) • Safety: \(route.safetyScore)/100")
        }
        if let notes = entry.notes, !notes.isEmpty { parts.append("📝 \(notes)") }
        parts.append("")
        parts.append("— Shared via ForeWiz")
        return parts.joined(separator: "\n")
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600; let m = (Int(duration) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }; return "\(m)m"
    }

    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 { return String(format: "%.1f km", distance / 1000) }
        return String(format: "%.0f m", distance)
    }
}
