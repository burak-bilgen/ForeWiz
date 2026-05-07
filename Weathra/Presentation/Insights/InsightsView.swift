import SwiftUI

struct InsightsView: View {
    let recommendation: DailyRecommendation
    let isPremium: Bool
    @Binding var showPaywall: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppBackground()

            if isPremium {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Label(L10n.text( "premium_feature_analytics"), systemImage: "chart.line.uptrend.xyaxis")
                                .font(AppTypography.largeTitle)
                                .foregroundStyle(AppTheme.ink)

                            Text(L10n.text( "premium_feature_analytics_desc"))
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .padding(.horizontal, AppSpacing.medium)

                        ScoreBreakdownCard(recommendation: recommendation)
                        ActivitySummaryCard(recommendation: recommendation)
                        WeeklyTrendPlaceholder()
                    }
                    .padding(.vertical, AppSpacing.medium)
                }
            } else {
                VStack(spacing: AppSpacing.large) {
                    Spacer()

                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(AppTheme.sunshine.opacity(0.6))

                    Text(L10n.text( "premium_feature_analytics"))
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(AppTheme.ink)

                    Text(L10n.text( "premium_feature_analytics_desc"))
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xLarge)

                    Button(action: { showPaywall = true }) {
                        Label(L10n.text( "premium_upgrade"), systemImage: "crown.fill")
                            .font(AppTypography.headline)
                            .padding(.horizontal, AppSpacing.xLarge)
                            .padding(.vertical, AppSpacing.medium)
                            .background(AppTheme.weatherGradient(for: colorScheme), in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
        }
        .navigationTitle(L10n.text( "premium_feature_analytics"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ScoreBreakdownCard: View {
    let recommendation: DailyRecommendation

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(L10n.text( "insights_score_breakdown"), systemImage: "chart.pie.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                HStack(spacing: AppSpacing.large) {
                    ScoreRingView(score: recommendation.outdoorScore, size: 80)

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        ScoreRow(
                            label: L10n.text( "insights_temperature"),
                            value: recommendation.outdoorScore.rawValue > 60
                                ? L10n.text( "insights_comfortable")
                                : L10n.text( "insights_uncomfortable"),
                            color: AppTheme.accent
                        )
                        ScoreRow(
                            label: L10n.text( "insights_precipitation"),
                            value: L10n.text( "insights_low_risk"),
                            color: AppTheme.success
                        )
                        ScoreRow(
                            label: L10n.text( "insights_wind"),
                            value: L10n.text( "insights_calm"),
                            color: AppTheme.teal
                        )
                        ScoreRow(
                            label: L10n.text( "insights_uv_index"),
                            value: L10n.text( "insights_moderate"),
                            color: AppTheme.sunshine
                        )
                    }
                }
            }
        }
    }
}

private struct ScoreRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
        }
    }
}

private struct ActivitySummaryCard: View {
    let recommendation: DailyRecommendation

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(L10n.text( "insights_activity_scores"), systemImage: "figure.run")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                ForEach(recommendation.bestActivityWindows, id: \.id) { window in
                    HStack {
                        Image(systemName: iconName(for: window.activityType))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 24)
                        Text(window.activityType.localizedTitle)
                            .font(AppTypography.caption.weight(.semibold))
                        Spacer()
                        Text("\(window.score.rawValue)/100")
                            .font(AppTypography.caption.weight(.bold))
                            .foregroundStyle(AppTheme.color(for: OutdoorDecision(score: window.score)))
                    }
                }
            }
        }
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

private struct WeeklyTrendPlaceholder: View {
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(L10n.text( "insights_weekly_trend"), systemImage: "chart.line.uptrend.xyaxis")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                HStack(spacing: AppSpacing.small) {
                    ForEach(0..<7, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: AppTheme.compactRadius)
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(height: CGFloat.random(in: 30...80))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)

                Text(L10n.text( "insights_trend_description"))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView(recommendation: .placeholder, isPremium: true, showPaywall: .constant(false))
    }
}
