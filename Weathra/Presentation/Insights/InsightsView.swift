import SwiftUI

struct InsightsView: View {
    let recommendation: DailyRecommendation
    let isPremium: Bool
    @Binding var showPaywall: Bool

    var body: some View {
        NavigationStack {
            if isPremium {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(L10n.text("premium_feature_analytics"), systemImage: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32, weight: .bold))
                            Text(L10n.text("premium_feature_analytics_desc"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)

                        ModernScoreBreakdownCard(recommendation: recommendation)
                        ModernActivitySummaryCard(recommendation: recommendation)
                        ModernWeeklyTrendPlaceholder()
                    }
                    .padding(.vertical, 20)
                }
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                VStack(spacing: 32) {
                    Spacer()

                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.blue.opacity(0.6))

                    Text(L10n.text("premium_feature_analytics"))
                        .font(.system(size: 28, weight: .bold))

                    Text(L10n.text("premium_feature_analytics_desc"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Button(
                        action: { showPaywall = true },
                        label: {
                            Label(L10n.text("premium_upgrade"), systemImage: "crown.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(.blue, in: Capsule())
                        }
                    )
                    .buttonStyle(.plain)

                    Spacer()
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .navigationTitle(L10n.text("premium_feature_analytics"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ModernScoreBreakdownCard: View {
    let recommendation: DailyRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("insights_score_breakdown"))
                .font(.headline)

            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", recommendation.outdoorScore.displayValue))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("Skor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ModernScoreRow(
                        label: L10n.text("insights_temperature"),
                        value: recommendation.outdoorScore.rawValue > 60
                            ? L10n.text("insights_comfortable")
                            : L10n.text("insights_uncomfortable"),
                        color: .blue
                    )
                    ModernScoreRow(
                        label: L10n.text("insights_precipitation"),
                        value: L10n.text("insights_low_risk"),
                        color: .green
                    )
                    ModernScoreRow(
                        label: L10n.text("insights_wind"),
                        value: L10n.text("insights_calm"),
                        color: .cyan
                    )
                    ModernScoreRow(
                        label: L10n.text("insights_uv_index"),
                        value: L10n.text("insights_moderate"),
                        color: .orange
                    )
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernScoreRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

private struct ModernActivitySummaryCard: View {
    let recommendation: DailyRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("insights_activity_scores"))
                .font(.headline)

            ForEach(recommendation.bestActivityWindows, id: \.id) { window in
                HStack {
                    Image(systemName: iconName(for: window.activityType))
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    Text(window.activityType.localizedTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(window.score.rawValue)/100")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func iconName(for type: ActivityType) -> String {
        switch type {
        case .running: "figure.run"
        case .walking: "figure.walk"
        case .cycling: "bicycle"
        case .goingOutside: "sun.max.fill"
        }
    }
}

private struct ModernWeeklyTrendPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("insights_weekly_trend"))
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.opacity(0.15))
                        .frame(height: CGFloat.random(in: 30...80))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)

            Text(L10n.text("insights_trend_description"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

#Preview {
    NavigationStack {
        InsightsView(recommendation: .placeholder, isPremium: true, showPaywall: .constant(false))
    }
}
