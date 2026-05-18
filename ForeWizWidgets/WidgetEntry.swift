import Foundation
import WidgetKit

/// Describes the state of the widget when no fresh data is available.
enum WidgetEmptyState: Equatable, Sendable {
    /// No data has ever been saved (first launch / app never ran).
    case awaitingFirstData
    /// The shared UserDefaults app group suite is unavailable.
    case configurationError
    /// Stored data was corrupted or from an incompatible version.
    case corruptedData(String)
    /// Data is stale but we show a degraded view (with a hint to open the app).
    case staleData
}

/// Timeline entry for the ForeWiz widget, wrapping cached weather data.
struct ForeWizWidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: WeatherWidgetData?
    let emptyState: WidgetEmptyState?

    /// Whether this entry has usable weather data.
    var hasData: Bool { widgetData != nil }

    static let awaitingFirstData = ForeWizWidgetEntry(
        date: Date(),
        widgetData: nil,
        emptyState: .awaitingFirstData
    )

    static let configurationError = ForeWizWidgetEntry(
        date: Date(),
        widgetData: nil,
        emptyState: .configurationError
    )

    static func with(data: WeatherWidgetData, at date: Date = Date(), isStale: Bool = false) -> ForeWizWidgetEntry {
        ForeWizWidgetEntry(
            date: date,
            widgetData: data,
            emptyState: isStale ? .staleData : nil
        )
    }
}
