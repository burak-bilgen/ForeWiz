import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: DailyRecommendation

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    DetailHeroCard(recommendation: recommendation)
                    DetailExplanationCard(explanation: recommendation.explanation)

                    if recommendation.bestActivityWindows.isEmpty == false {
                        DetailActivityTimeline(activities: recommendation.bestActivityWindows)
                    }

                    DetailOutfitCard(outfit: recommendation.outfit)

                    if recommendation.avoidWindows.isEmpty == false {
                        DetailAvoidCard(avoidWindows: recommendation.avoidWindows)
                    }

                    if recommendation.risks.isEmpty == false {
                        DetailRiskList(risks: recommendation.risks)
                    }
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.top, AppSpacing.medium)
                .padding(.bottom, AppSpacing.xLarge)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(L10n.text("premium_feature_hourly"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DetailHeroCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let recommendation: DailyRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .center, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(recommendation.outdoorDecision.localizedTitle)
                        .font(.system(.title, design: .rounded, weight: .heavy))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(recommendation.summaryText)
                        .font(AppTypography.body)
                        .foregroundStyle(.white.opacity(colorScheme == .dark ? 0.78 : 0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.small)

                ScoreRingView(score: recommendation.outdoorScore)
                    .colorInvert()
            }

            if let bestWindow = recommendation.bestOutdoorWindow {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "clock.fill")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(colorScheme == .dark ? 0.25 : 0.18), in: Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text(L10n.text("widget_best_time"))
                            .font(AppTypography.caption)
                            .foregroundStyle(.white.opacity(colorScheme == .dark ? 0.65 : 0.76))
                        Text(bestWindow.shortDisplayText)
                            .font(AppTypography.headline)
                    }
                }
                .padding(AppSpacing.small)
                .background(.white.opacity(colorScheme == .dark ? 0.18 : 0.14), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
            }
        }
        .foregroundStyle(.white)
        .padding(AppSpacing.large)
        .background(AppTheme.weatherGradient(for: colorScheme), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: AppTheme.accent.opacity(0.20), radius: 22, y: 12)
    }
}

private struct DetailExplanationCard: View {
    let explanation: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Label(L10n.text("decision_moderate"), systemImage: "lightbulb.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                Text(explanation)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct DetailActivityTimeline: View {
    let activities: [ActivityRecommendation]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(L10n.text("notification_best_run"), systemImage: "figure.run")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                ForEach(activities) { activity in
                    HStack(alignment: .center, spacing: AppSpacing.medium) {
                        Image(systemName: iconName(for: activity.activityType))
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.softBubbleGradient(tint: tint(for: activity.score)), in: Circle())
                            .foregroundStyle(tint(for: activity.score))

                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(activity.activityType.localizedTitle)
                                .font(AppTypography.headline)
                                .foregroundStyle(AppTheme.ink)

                            Text(activity.bestWindow.shortDisplayText)
                                .font(AppTypography.title3)
                                .foregroundStyle(AppTheme.ink)

                            Text(activity.reason)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Text(activity.score.displayValue.formatted(.number.precision(.fractionLength(1))))
                            .font(AppTypography.headline)
                            .foregroundStyle(tint(for: activity.score))
                            .padding(.horizontal, AppSpacing.small)
                            .padding(.vertical, AppSpacing.xSmall)
                            .background(tint(for: activity.score).opacity(0.12), in: Capsule())
                    }

                    if activity.id != activities.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private func iconName(for type: ActivityType) -> String {
        switch type {
        case .running:
            "figure.run"
        case .walking, .goingOutside:
            "figure.walk"
        case .cycling:
            "bicycle"
        }
    }

    private func tint(for score: WeatherScore) -> Color {
        switch score.rawValue {
        case 80...100:
            AppTheme.success
        case 60..<80:
            AppTheme.accent
        case 40..<60:
            AppTheme.warning
        default:
            AppTheme.danger
        }
    }
}

private struct DetailOutfitCard: View {
    let outfit: OutfitRecommendation

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(L10n.text("notification_outfit"), systemImage: "tshirt.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                Text(outfit.title)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if outfit.items.isEmpty == false {
                    FlowLayout(spacing: AppSpacing.small) {
                        ForEach(outfit.items, id: \.self) { item in
                            Text(item)
                                .font(AppTypography.caption)
                                .lineLimit(1)
                                .foregroundStyle(AppTheme.ink)
                                .padding(.horizontal, AppSpacing.small)
                                .padding(.vertical, AppSpacing.xSmall)
                                .background(AppTheme.elevatedSurface, in: Capsule())
                        }
                    }
                }

                if outfit.accessories.isEmpty == false {
                    InsightRow(
                        icon: "sparkles",
                        title: L10n.text("wardrobe_umbrella"),
                        value: outfit.accessories.joined(separator: " • "),
                        tint: AppTheme.teal
                    )
                }

                if let warning = outfit.warning {
                    InsightRow(
                        icon: "exclamationmark.triangle.fill",
                        title: L10n.text("risk_high"),
                        value: warning,
                        tint: AppTheme.warning
                    )
                }
            }
        }
    }
}

private struct DetailAvoidCard: View {
    let avoidWindows: [AvoidWindowRecommendation]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(L10n.text("decision_risky"), systemImage: "exclamationmark.octagon.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                ForEach(avoidWindows) { warning in
                    InsightRow(
                        icon: iconName(for: warning.risk.type),
                        title: "\(warning.window.shortDisplayText) · \(warning.risk.title)",
                        value: warning.reason,
                        tint: AppTheme.color(for: warning.severity)
                    )
                }
            }
        }
    }

    private func iconName(for riskType: WeatherRiskType) -> String {
        switch riskType {
        case .heat:
            "thermometer.sun.fill"
        case .uv:
            "sun.max.fill"
        case .rain:
            "cloud.rain.fill"
        case .wind:
            "wind"
        case .humidity:
            "humidity.fill"
        case .cold:
            "snowflake"
        case .storm:
            "cloud.bolt.rain.fill"
        case .poorComfort:
            "exclamationmark.circle.fill"
        case .pollen:
            "leaf.fill"
        case .airQuality:
            "aqi.medium"
        }
    }
}

private struct DetailRiskList: View {
    let risks: [WeatherRisk]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(L10n.text("decision_risky"), systemImage: "exclamationmark.triangle.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                ForEach(risks) { risk in
                    HStack(alignment: .top, spacing: AppSpacing.medium) {
                        RiskBadgeView(risk: risk)
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(risk.title)
                                .font(AppTypography.headline)
                                .foregroundStyle(AppTheme.ink)
                            Text(risk.message)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }

                    if risk.id != risks.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }
}
