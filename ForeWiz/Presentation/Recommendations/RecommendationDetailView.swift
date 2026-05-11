import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: DailyRecommendation
    @State private var appeared = false

    var body: some View {
        ZStack {
            DetailBackground().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    DetailHeroCard(recommendation: recommendation)
                        .staggerEntrance(index: 0, appeared: appeared)
                    DetailExplanationCard(explanation: recommendation.explanation)
                        .staggerEntrance(index: 1, appeared: appeared)
                    if !recommendation.bestActivityWindows.isEmpty {
                        DetailActivityCard(activities: recommendation.bestActivityWindows)
                            .staggerEntrance(index: 2, appeared: appeared)
                    }
                    DetailOutfitCard(outfit: recommendation.outfit)
                        .staggerEntrance(index: 3, appeared: appeared)
                    if !recommendation.avoidWindows.isEmpty {
                        DetailAvoidCard(avoidWindows: recommendation.avoidWindows)
                            .staggerEntrance(index: 4, appeared: appeared)
                    }
                    if !recommendation.risks.isEmpty {
                        DetailRiskCard(risks: recommendation.risks)
                            .staggerEntrance(index: 5, appeared: appeared)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.bottom, 12)
        }
        .navigationTitle(L10n.text("recommendation_detail_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .dynamicTypeSize(.large ... .xxxLarge)
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Background

private struct DetailBackground: View {
    var body: some View {
        AnimatedOrbBackground(
            primary:   Color(red: 0.30, green: 0.55, blue: 1.00),
            secondary: Color(red: 0.60, green: 0.35, blue: 1.00),
            tertiary:  Color(red: 0.20, green: 0.75, blue: 0.90)
        )
    }
}

// MARK: - Shared card

private struct DetailCard<Content: View>: View {
    let accentColor: Color
    let content: Content
    init(accentColor: Color = Color(red: 0.4, green: 0.7, blue: 1.0), @ViewBuilder content: () -> Content) {
        self.accentColor = accentColor
        self.content = content()
    }
    var body: some View {
        content
            .padding(18)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(accentColor.opacity(0.14), lineWidth: 1))
    }
}

private struct DetailSectionLabel: View {
    let title: String
    let icon: String
    var color: Color = Color(red: 0.4, green: 0.7, blue: 1.0)
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.45))
                .textCase(.uppercase)
                .tracking(0.5)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }
}

// MARK: - Hero card

private struct DetailHeroCard: View {
    let recommendation: DailyRecommendation
    private let sky = Color(red: 0.40, green: 0.72, blue: 1.0)
    private let decisionColor: Color

    init(recommendation: DailyRecommendation) {
        self.recommendation = recommendation
        self.decisionColor = AppTheme.color(for: recommendation.outdoorDecision)
    }

    var body: some View {
        DetailCard(accentColor: sky) {
            VStack(spacing: 18) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        heroCopy
                        Spacer(minLength: 12)
                        scoreRing
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        heroCopy
                        scoreRing
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                if let bestWindow = recommendation.bestOutdoorWindow {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(bestWindow.shortDisplayText)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(sky)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(sky.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(decisionColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: decisionColor.opacity(0.8), radius: 5)
                    .pulseGlow(color: decisionColor, radius: 6)
                Text(recommendation.outdoorDecision.localizedTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.80)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(recommendation.summaryText)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
    }

    private var scoreRing: some View {
        ScoreRingView(score: recommendation.outdoorScore, size: 76, showOutOf100: true)
            .environment(\.colorScheme, .dark)
    }
}

// MARK: - Explanation card

private struct DetailExplanationCard: View {
    let explanation: String
    var body: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 10) {
                DetailSectionLabel(title: L10n.text("recommendation_detail_title"), icon: "text.alignleft")
                Text(explanation)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Activity card

private struct DetailActivityCard: View {
    let activities: [ActivityRecommendation]
    var body: some View {
        DetailCard(accentColor: Color(red: 0.4, green: 0.85, blue: 0.6)) {
            VStack(alignment: .leading, spacing: 14) {
                DetailSectionLabel(title: L10n.text("home_activity_label"), icon: "figure.run", color: Color(red: 0.4, green: 0.85, blue: 0.6))
                VStack(spacing: 4) {
                    ForEach(activities) { activity in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(activity.activityType.localizedTitle)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                Text(activity.bestWindow.shortDisplayText)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white.opacity(0.4))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .layoutPriority(1)
                            Spacer(minLength: 8)
                            Text(String(format: "%.0f", activity.score.displayValue))
                                .font(.system(size: 20, weight: .thin, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                        }
                        .padding(.vertical, 6)
                        if activity.id != activities.last?.id {
                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Outfit card

private struct DetailOutfitCard: View {
    let outfit: OutfitRecommendation
    var body: some View {
        DetailCard(accentColor: Color(red: 0.8, green: 0.65, blue: 1.0)) {
            VStack(alignment: .leading, spacing: 14) {
                DetailSectionLabel(title: L10n.text("home_outfit_label"), icon: "tshirt.fill", color: Color(red: 0.8, green: 0.65, blue: 1.0))
                Text(outfit.title)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
                if !outfit.items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(outfit.items, id: \.self) { item in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(red: 0.8, green: 0.65, blue: 1.0))
                                Text(item)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.75))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                if !outfit.accessories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(outfit.accessories, id: \.self) { accessory in
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(red: 0.8, green: 0.65, blue: 1.0))
                                Text(accessory)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.75))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                if let warning = outfit.warning {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.3))
                        Text(warning)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }
}

// MARK: - Avoid card

private struct DetailAvoidCard: View {
    let avoidWindows: [AvoidWindowRecommendation]
    var body: some View {
        DetailCard(accentColor: Color(red: 1.0, green: 0.7, blue: 0.3)) {
            VStack(alignment: .leading, spacing: 14) {
                DetailSectionLabel(title: L10n.text("home_risk_label"), icon: "exclamationmark.triangle.fill", color: Color(red: 1.0, green: 0.7, blue: 0.3))
                VStack(spacing: 4) {
                    ForEach(avoidWindows) { warning in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(warning.window.shortDisplayText) · \(warning.risk.title)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(warning.reason)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.45))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if warning.id != avoidWindows.last?.id {
                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Risk card

private struct DetailRiskCard: View {
    let risks: [WeatherRisk]
    var body: some View {
        DetailCard(accentColor: Color(red: 1.0, green: 0.45, blue: 0.45)) {
            VStack(alignment: .leading, spacing: 14) {
                DetailSectionLabel(title: L10n.text("home_risk_label"), icon: "exclamationmark.shield.fill", color: Color(red: 1.0, green: 0.45, blue: 0.45))
                VStack(spacing: 4) {
                    ForEach(risks) { risk in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(severityColor(risk.severity).opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: riskIcon(risk.type))
                                    .font(.system(size: 13))
                                    .foregroundStyle(severityColor(risk.severity))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(risk.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                Text(risk.message)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white.opacity(0.45))
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .layoutPriority(1)
                            Spacer(minLength: 8)
                        }
                        .padding(.vertical, 6)
                        if risk.id != risks.last?.id {
                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private func severityColor(_ s: RiskLevel) -> Color {
        switch s {
        case .low: Color(red: 0.35, green: 0.85, blue: 0.6)
        case .medium: Color(red: 1.0, green: 0.7, blue: 0.3)
        case .high: Color(red: 1.0, green: 0.45, blue: 0.45)
        case .extreme: Color(red: 0.75, green: 0.35, blue: 1.0)
        }
    }

    private func riskIcon(_ type: WeatherRiskType) -> String {
        switch type {
        case .heat: "thermometer.sun.fill"
        case .uv: "sun.max.fill"
        case .rain: "cloud.rain.fill"
        case .wind: "wind"
        case .humidity: "humidity.fill"
        case .cold: "snowflake"
        case .storm: "cloud.bolt.rain.fill"
        case .poorComfort: "exclamationmark.circle.fill"
        case .pollen: "leaf.fill"
        case .airQuality: "aqi.medium"
        }
    }
}
