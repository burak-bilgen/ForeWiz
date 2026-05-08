import SwiftUI

struct InsightsView: View {
    let recommendation: DailyRecommendation
    let isPremium: Bool
    @Binding var showPaywall: Bool

    var body: some View {
        ZStack {
            InsightsBackground().ignoresSafeArea()
            if isPremium {
                ScrollView {
                    VStack(spacing: 20) {
                        InsightsHeader()
                        InsightsScoreCard(recommendation: recommendation)
                        InsightsActivityCard(recommendation: recommendation)
                        InsightsTrendCard()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.hidden)
            } else {
                InsightsLockedView(onUpgrade: { showPaywall = true })
            }
        }
        .navigationTitle(L10n.text("premium_feature_analytics"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Background

private struct InsightsBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.06, green: 0.12, blue: 0.26)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.09))
                .frame(width: 320).blur(radius: 70)
                .offset(x: 120, y: -150)
            Circle()
                .fill(Color(red: 0.35, green: 0.85, blue: 0.6).opacity(0.06))
                .frame(width: 250).blur(radius: 55)
                .offset(x: -100, y: 300)
        }
    }
}

// MARK: - Header

private struct InsightsHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                Text(L10n.text("premium_feature_analytics"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(L10n.text("premium_feature_analytics_desc"))
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// MARK: - Score card

private struct InsightsScoreRow: Identifiable {
    let id: String
    let label: String
    let color: Color
}

private struct InsightsScoreCard: View {
    let recommendation: DailyRecommendation

    private var rows: [InsightsScoreRow] {
        [
            InsightsScoreRow(id: "temp",  label: L10n.text("insights_temperature"),  color: Color(red: 0.4, green: 0.7, blue: 1.0)),
            InsightsScoreRow(id: "precip",label: L10n.text("insights_precipitation"), color: Color(red: 0.35, green: 0.85, blue: 0.6)),
            InsightsScoreRow(id: "wind",  label: L10n.text("insights_wind"),          color: Color(red: 0.55, green: 0.85, blue: 1.0)),
            InsightsScoreRow(id: "uv",    label: L10n.text("insights_uv_index"),      color: Color(red: 1.0, green: 0.7, blue: 0.3)),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "gauge.medium")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                Text(L10n.text("insights_score_breakdown"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", recommendation.outdoorScore.displayValue))
                        .font(.system(size: 52, weight: .thin, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(L10n.text("home_score_label"))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.35))
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(rows) { row in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(row.color)
                                .frame(width: 7, height: 7)
                            Text(row.label)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Spacer()
                            Text(recommendation.outdoorScore.rawValue > 60
                                 ? L10n.text("insights_comfortable")
                                 : L10n.text("insights_uncomfortable"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(row.color)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.14), lineWidth: 1))
    }
}

// MARK: - Activity card

private struct InsightsActivityCard: View {
    let recommendation: DailyRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                Text(L10n.text("insights_activity_scores"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            if recommendation.bestActivityWindows.isEmpty {
                Text(L10n.text("home_activity_label"))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.35))
            } else {
                VStack(spacing: 4) {
                    ForEach(recommendation.bestActivityWindows) { window in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(red: 0.4, green: 0.85, blue: 0.6).opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: activityIcon(window.activityType))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                            }
                            Text(window.activityType.localizedTitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(window.score.rawValue)/100")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                                .monospacedDigit()
                        }
                        .padding(.vertical, 6)
                        if window.id != recommendation.bestActivityWindows.last?.id {
                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(red: 0.4, green: 0.85, blue: 0.6).opacity(0.14), lineWidth: 1))
    }

    private func activityIcon(_ type: ActivityType) -> String {
        switch type {
        case .running: "figure.run"
        case .walking: "figure.walk"
        case .cycling: "bicycle"
        case .goingOutside: "sun.max.fill"
        }
    }
}

// MARK: - Trend card

private struct InsightsTrendCard: View {
    private let barHeights: [CGFloat] = [48, 36, 62, 70, 44, 55, 68]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.75, green: 0.5, blue: 1.0))
                Text(L10n.text("insights_weekly_trend"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(barHeights.enumerated()), id: \.offset) { _, height in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.75, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.7, blue: 1.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .opacity(0.45)
                        .frame(height: height)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)

            Text(L10n.text("insights_trend_description"))
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.35))
        }
        .padding(18)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(red: 0.75, green: 0.5, blue: 1.0).opacity(0.14), lineWidth: 1))
    }
}

// MARK: - Locked view

private struct InsightsLockedView: View {
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: 8) {
                Text(L10n.text("premium_feature_analytics"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(L10n.text("premium_feature_analytics_desc"))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button(action: onUpgrade) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text(L10n.text("premium_upgrade"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.18))
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.82, blue: 0.3), Color(red: 1.0, green: 0.65, blue: 0.2)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView(recommendation: .placeholder, isPremium: true, showPaywall: .constant(false))
    }
}
