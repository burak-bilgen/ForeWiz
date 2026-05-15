import Foundation
import WidgetKit

/// Provides timeline entries for the ForeWiz widget by reading cached weather data
/// from the shared app group UserDefaults.
struct ForeWizWidgetProvider: TimelineProvider {
    typealias Entry = ForeWizWidgetEntry

    func placeholder(in context: Context) -> Entry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = cachedEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = cachedEntry()
        // Refresh every 60 minutes, or sooner if the app pushes an update.
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 60, to: Date()) ?? Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    // MARK: - Helpers

    private func cachedEntry() -> ForeWizWidgetEntry {
        if let data = WeatherWidgetData.load() {
            return .with(data: data)
        }
        return .placeholder
    }
}
