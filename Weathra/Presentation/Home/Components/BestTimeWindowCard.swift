import SwiftUI

struct BestTimeWindowCard: View {
    let title: String
    let window: TimeWindow?
    @State private var isAppeared = false

    var body: some View {
        GlassCard {
            InsightRow(
                icon: "sun.max.fill",
                title: title,
                value: window?.shortDisplayText ?? String(localized: "forecast_no_best_window"),
                tint: AppTheme.accent
            )
        }
        .opacity(isAppeared ? 1 : 0)
        .offset(y: isAppeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAppeared = true
            }
        }
    }
}
