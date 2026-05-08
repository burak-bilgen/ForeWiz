import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: DailyRecommendation

    var body: some View {
        ZStack {
            DetailBackground().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    DetailHeroCard(recommendation: recommendation)
                    DetailExplanationCard(explanation: recommendation.explanation)
                    if !recommendation.bestActivityWindows.isEmpty {
                        DetailActivityCard(activities: recommendation.bestActivityWindows)
                    }
                    DetailOutfitCard(outfit: recommendation.outfit)
                    if !recommendation.avoidWindows.isEmpty {
                        DetailAvoidCard(avoidWindows: recommendation.avoidWindows)
                    }
                    if !recommendation.risks.isEmpty {
                        DetailRiskCard(risks: recommendation.risks)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(L10n.text("recommendation_detail_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Background

private struct DetailBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.06, green: 0.12, blue: 0.26)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.blue.opacity(0.09))
                .frame(width: 300).blur(radius: 65)
                .offset(x: 100, y: -160)
            Circle()
                .fill(Color(red: 0.8, green: 0.65, blue: 1.0).opacity(0.06))
                .frame(width: 220).blur(radius: 50)
                .offset(x: -80, y: 280)
        }
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
        }
    }
}

// MARK: - Hero card

private struct DetailHeroCard: View {
    let recommendation: DailyRecommendation
    var body: some View {
        DetailCard(accentColor: Color(red: 0.4, green: 0.7, blue: 1.0)) {
            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recommendation.outdoorDecision.localizedTitle)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(recommendation.summaryText)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .lineLimit(3)
                    }
                    Spacer(minLength: 16)
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f", recommendation.outdoorScore.displayValue))
                            .font(.system(size: 42, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text(L10n.text("home_score_label"))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                }
                if let bestWindow = recommendation.bestOutdoorWindow {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(bestWindow.shortDisplayText)
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
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
                                Text(activity.bestWindow.shortDisplayText)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                            Spacer()
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
                if !outfit.items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(outfit.items, id: \.self) { item in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(red: 0.8, green: 0.65, blue: 1.0))
                                Text(item).font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.75))
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
                                Text(accessory).font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.75))
                            }
                        }
                    }
                }
                if let warning = outfit.warning {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.3))
                        Text(warning).font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.7))
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
                            Text(warning.reason)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.45))
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
                                Text(risk.message)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white.opacity(0.45))
                                    .lineLimit(2)
                            }
                            Spacer()
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
