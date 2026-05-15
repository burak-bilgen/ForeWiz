import Foundation
import WidgetKit

/// Timeline entry for the ForeWiz widget, wrapping cached weather data.
struct ForeWizWidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: WeatherWidgetData?
    let isPlaceholder: Bool

    static let placeholder = ForeWizWidgetEntry(
        date: Date(),
        widgetData: nil,
        isPlaceholder: true
    )

    static func with(data: WeatherWidgetData, at date: Date = Date()) -> ForeWizWidgetEntry {
        ForeWizWidgetEntry(date: date, widgetData: data, isPlaceholder: false)
    }
}
