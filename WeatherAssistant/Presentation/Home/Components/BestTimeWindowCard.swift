import SwiftUI

struct BestTimeWindowCard: View {
    let title: String
    let window: TimeWindow?

    var body: some View {
        GlassCard {
            InsightRow(
                icon: "sun.max.fill",
                title: title,
                value: window?.shortDisplayText ?? "Bugün belirgin iyi pencere yok",
                tint: AppTheme.accent
            )
        }
    }
}
