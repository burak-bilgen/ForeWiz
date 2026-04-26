import SwiftUI

struct BestTimeWindowCard: View {
    let title: String
    let window: TimeWindow?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(title)
                    .font(AppTypography.headline)
                Text(window?.shortDisplayText ?? "Bugün belirgin iyi pencere yok")
                    .font(AppTypography.title)
            }
        }
    }
}
