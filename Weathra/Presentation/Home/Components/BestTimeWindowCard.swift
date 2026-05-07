import SwiftUI

struct BestTimeWindowCard: View {
    let title: String
    let window: TimeWindow?

    var body: some View {
        GlassCard {
            InsightRow(
                icon: "sun.max.fill",
                title: title,
                value: window?.shortDisplayText ?? L10n.text("forecast_no_best_window"),
                tint: AppTheme.accent
            )
        }
    }
}
