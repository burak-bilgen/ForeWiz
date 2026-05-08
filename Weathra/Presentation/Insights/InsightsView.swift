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
                        InsightsDayQualityCard(recommendation: recommendation)
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

private struct InsightsScoreCard: View {
    let recommendation: DailyRecommendation

    private struct FactorRow: Identifiable {
        let id: String
        let label: String
        let icon: String
        let status: String
        let color: Color
    }

    private var factors: [FactorRow] {
        let riskTypes: [(WeatherRiskType, String, String, Color)] = [
            (.heat,     L10n.text("insights_temperature"),  "thermometer.sun.fill",  Color(red: 1.0, green: 0.55, blue: 0.3)),
            (.rain,     L10n.text("insights_precipitation"), "cloud.rain.fill",        Color(red: 0.4, green: 0.7,  blue: 1.0)),
            (.wind,     L10n.text("insights_wind"),          "wind",                   Color(red: 0.55, green: 0.85, blue: 1.0)),
            (.uv,       L10n.text("insights_uv_index"),      "sun.max.fill",           Color(red: 1.0, green: 0.7,  blue: 0.3)),
            (.cold,     L10n.text("insights_temperature"),   "snowflake",              Color(red: 0.7,  green: 0.85, blue: 1.0)),
            (.humidity, L10n.text("insights_wind"),          "humidity.fill",          Color(red: 0.55, green: 0.85, blue: 1.0)),
        ]

        var rows: [FactorRow] = []
        var seenLabels = Set<String>()
        for (type, label, icon, color) in riskTypes {
            guard !seenLabels.contains(label) else { continue }
            let risk = recommendation.risks.first { $0.type == type }
            let status: String
            let finalColor: Color
            if let risk {
                switch risk.severity {
                case .low:     status = L10n.text("insights_comfortable");   finalColor = Color(red: 0.4, green: 0.85, blue: 0.6)
                case .medium:  status = L10n.text("insights_uncomfortable"); finalColor = Color(red: 1.0, green: 0.7, blue: 0.3)
                case .high, .extreme: status = risk.title;                   finalColor = Color(red: 1.0, green: 0.45, blue: 0.45)
                }
            } else {
                status = L10n.text("insights_comfortable")
                finalColor = color
            }
            seenLabels.insert(label)
            rows.append(FactorRow(id: type.rawValue, label: label, icon: icon, status: status, color: finalColor))
        }
        return rows
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

            HStack(alignment: .top, spacing: 20) {
                ScoreRingView(score: recommendation.outdoorScore, size: 72)
                    .environment(\.colorScheme, .dark)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(factors) { row in
                        HStack(spacing: 8) {
                            Image(systemName: row.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(row.color)
                                .frame(width: 14)
                            Text(row.label)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Spacer()
                            Text(row.status)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(row.color)
                                .lineLimit(1)
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

// MARK: - Day quality card

private struct InsightsDayQualityCard: View {
    let recommendation: DailyRecommendation

    private struct HourBlock: Identifiable {
        let id: Int  // hour 0-23
        let quality: Quality
        enum Quality { case good, avoid, neutral }
    }

    private var hourBlocks: [HourBlock] {
        let calendar = Calendar.current
        let avoidHours: Set<Int> = Set(
            recommendation.avoidWindows.flatMap { avoid -> [Int] in
                let start = calendar.component(.hour, from: avoid.window.start)
                let end   = calendar.component(.hour, from: avoid.window.end)
                if start <= end { return Array(start...end) }
                return Array(start...23) + Array(0...end)
            }
        )
        let goodHours: Set<Int> = {
            guard let best = recommendation.bestOutdoorWindow else { return [] }
            let start = calendar.component(.hour, from: best.start)
            let end   = calendar.component(.hour, from: best.end)
            if start <= end { return Set(start...end) }
            return Set(Array(start...23) + Array(0...end))
        }()

        return (6...22).map { hour in
            let quality: HourBlock.Quality
            if avoidHours.contains(hour)      { quality = .avoid }
            else if goodHours.contains(hour)  { quality = .good }
            else                               { quality = .neutral }
            return HourBlock(id: hour, quality: quality)
        }
    }

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

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(hourBlocks) { block in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(barColor(block.quality))
                            .frame(height: barHeight(block.quality))
                            .frame(maxWidth: .infinity)
                        if block.id % 4 == 0 {
                            Text("\(block.id)h")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.white.opacity(0.3))
                        } else {
                            Color.clear.frame(height: 10)
                        }
                    }
                }
            }
            .frame(height: 90)

            HStack(spacing: 16) {
                legendDot(color: Color(red: 0.4, green: 0.85, blue: 0.6), label: L10n.text("insights_comfortable"))
                legendDot(color: Color(red: 1.0, green: 0.45, blue: 0.45), label: L10n.text("insights_uncomfortable"))
                legendDot(color: Color.white.opacity(0.2), label: L10n.text("insights_score_breakdown"))
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(red: 0.75, green: 0.5, blue: 1.0).opacity(0.14), lineWidth: 1))
    }

    private func barHeight(_ quality: HourBlock.Quality) -> CGFloat {
        switch quality {
        case .good:    return 64
        case .avoid:   return 32
        case .neutral: return 48
        }
    }

    private func barColor(_ quality: HourBlock.Quality) -> Color {
        switch quality {
        case .good:    return Color(red: 0.4, green: 0.85, blue: 0.6).opacity(0.7)
        case .avoid:   return Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.6)
        case .neutral: return Color.white.opacity(0.18)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.4))
        }
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
