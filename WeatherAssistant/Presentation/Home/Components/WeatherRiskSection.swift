import SwiftUI

struct WeatherRiskSection: View {
    let risks: [WeatherRisk]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Riskler")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                if risks.isEmpty {
                    Text("Bugün dikkat çeken hava riski yok.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    FlowLayout(spacing: AppSpacing.small) {
                        ForEach(risks) { risk in
                            RiskBadgeView(risk: risk)
                        }
                    }
                }
            }
        }
    }
}
