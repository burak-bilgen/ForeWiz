import Foundation
import WidgetKit

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

        var entries: [ForeWizWidgetEntry] = [entry]
        let calendar = Calendar.current
        for i in 1...3 {
            if let nextDate = calendar.date(byAdding: .minute, value: i * 30, to: now) {
                let nextEntry = entryFromCache(at: nextDate)
                entries.append(nextEntry)
            }
        }

        let lastEntryDate = entries.last?.date ?? now.addingTimeInterval(3600)
        let timeline = Timeline(entries: entries, policy: .after(lastEntryDate))
        completion(timeline)
    }

    private func entryFromCache(at date: Date = Date()) -> ForeWizWidgetEntry {
        let result = WeatherWidgetData.loadDetailed()

        switch result {
        case .success(let data):
            return .with(data: data, at: date, isStale: false)

        case .stale(let data, _):

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
