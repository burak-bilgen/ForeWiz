import Foundation
import WidgetKit

/// Provides timeline entries for the ForeWiz widget by reading cached weather data
/// from the shared app group UserDefaults.
struct ForeWizWidgetProvider: TimelineProvider {
    typealias Entry = ForeWizWidgetEntry

    func placeholder(in context: Context) -> Entry {
        .awaitingFirstData
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = entryFromCache(at: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date()
        let entry = entryFromCache(at: now)

        // Generate multiple timeline entries at 30-minute intervals so the widget
        // refreshes more frequently without requiring the app to push an update.
        // This ensures the "last updated" time stays relatively current.
        var entries: [ForeWizWidgetEntry] = [entry]
        let calendar = Calendar.current
        for i in 1...3 {
            if let nextDate = calendar.date(byAdding: .minute, value: i * 30, to: now) {
                let nextEntry = entryFromCache(at: nextDate)
                entries.append(nextEntry)
            }
        }

        // After the last entry, request a fresh timeline from the system
        let lastEntryDate = entries.last?.date ?? now.addingTimeInterval(3600)
        let timeline = Timeline(entries: entries, policy: .after(lastEntryDate))
        completion(timeline)
    }

    // MARK: - Helpers

    private func entryFromCache(at date: Date = Date()) -> ForeWizWidgetEntry {
        let result = WeatherWidgetData.loadDetailed()

        switch result {
        case .success(let data):
            return .with(data: data, at: date, isStale: false)

        case .stale(let data, let ageSeconds):
            // Still show data but mark as stale so the UI can show a warning
            return .with(data: data, at: date, isStale: true)

        case .noSuite:
            return .configurationError

        case .noData:
            return .awaitingFirstData

        case .corrupted(let errorDescription):
            return ForeWizWidgetEntry(
                date: date,
                widgetData: nil,
                emptyState: .corruptedData(errorDescription)
            )
        }
    }
}
