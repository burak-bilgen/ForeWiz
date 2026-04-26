import SwiftUI

struct AvoidHoursCard: View {
    let avoidWindows: [AvoidWindowRecommendation]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Label("Kaçınılacak saatler", systemImage: "exclamationmark.octagon.fill")
                    .font(AppTypography.headline)

                if avoidWindows.isEmpty {
                    Text("Bugün belirgin kaçınılacak saat yok.")
                        .font(AppTypography.body)
                } else {
                    ForEach(avoidWindows) { warning in
                        Text("\(warning.window.shortDisplayText) • \(warning.reason)")
                            .font(AppTypography.body)
                    }
                }
            }
        }
    }
}
