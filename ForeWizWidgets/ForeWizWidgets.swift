import SwiftUI
import WidgetKit

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
        .configurationDisplayName(WidgetL10n.text("widget_config_name"))
        .description(WidgetL10n.text("widget_config_desc"))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
