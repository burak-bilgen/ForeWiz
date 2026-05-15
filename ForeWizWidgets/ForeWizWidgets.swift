import SwiftUI
import WidgetKit

/// ForeWiz widget bundle — offers a medium (default) and small widget variant
/// that displays current weather conditions and outdoor activity scores.
@main
struct ForeWizWidgets: WidgetBundle {
    var body: some Widget {
        ForeWizWidget()
    }
}

struct ForeWizWidget: Widget {
    let kind: String = "com.forewiz.widget.weather"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: ForeWizWidgetProvider()
        ) { entry in
            ForeWizWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather Forecast")
        .description("Your daily outdoor score and forecast at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
