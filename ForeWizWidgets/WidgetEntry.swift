import Foundation
import WidgetKit

enum WidgetEmptyState: Equatable, Sendable {

    case awaitingFirstData

    case configurationError

    case corruptedData(String)

    case staleData
}

struct ForeWizWidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: WeatherWidgetData?
    let emptyState: WidgetEmptyState?

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
