import SwiftUI

// MARK: - Background

struct InsightsBackground: View {
    var body: some View {
        AnimatedOrbBackground(
            primary:   Color(red: 0.25, green: 0.55, blue: 1.0),
            secondary: Color(red: 0.20, green: 0.80, blue: 0.60),
            tertiary:  Color(red: 0.55, green: 0.35, blue: 1.0)
        )
    }
}

// MARK: - Header

struct InsightsHeader: View {
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                Text(L10n.text("insights_title"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear { withAnimation(AppTheme.sheetSpring.delay(AppTheme.staggerDelay)) { appeared = true } }
    }
}

// MARK: - Score Card

struct InsightsScoreCard: View {
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

    @State private var appeared = false

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

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 18) {
                    scoreRing
                    factorsList
                }
                VStack(alignment: .leading, spacing: 14) {
                    scoreRing
                        .frame(maxWidth: .infinity, alignment: .center)
                    factorsList
                }
            }
        }
        .padding(18)
        .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onAppear { withAnimation { appeared = true } }
    }

    private var scoreRing: some View {
        ScoreRingView(score: recommendation.outdoorScore, size: 88, showOutOf100: false)
            .environment(\.colorScheme, .dark)
    }

    private var factorsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(factors.enumerated()), id: \.element.id) { index, row in
                HStack(spacing: 8) {
                    Image(systemName: row.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(row.color)
                        .frame(width: 14)
                    Text(row.label)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .lineLimit(2)
                        .layoutPriority(1)
                    Spacer(minLength: 8)
                    Text(row.status)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(row.color)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                .staggerEntrance(index: index, appeared: appeared, baseDelay: 0.06)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Activity Card

struct InsightsActivityCard: View {
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
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                            }
                            Text(window.activityType.localizedTitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .layoutPriority(1)
                            Spacer(minLength: 8)
                            Text("\(window.score.rawValue)\(L10n.text("insights_score_suffix_100"))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                                .monospacedDigit()
                                .lineLimit(1)
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
        .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Day Quality Card

struct InsightsDayQualityCard: View {
    let recommendation: DailyRecommendation

    private struct HourBlock: Identifiable {
        let id: Int
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
                ForEach(Array(hourBlocks.enumerated()), id: \.element.id) { index, block in
                    AnimatedBar(
                        height: barHeight(block.quality),
                        color: barColor(block.quality),
                        delay: Double(index) * 0.03
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)

            HStack(alignment: .top, spacing: 3) {
                ForEach(hourBlocks) { block in
                    if block.id % 4 == 0 {
                        Text("\(block.id)\(L10n.text("insights_hour_block_suffix"))")
                            .font(.system(size: 7))
                            .foregroundStyle(Color.white.opacity(0.28))
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 10)
                    }
                }
            }

            FlowLayout(spacing: 10) {
                legendDot(color: Color(red: 0.4, green: 0.85, blue: 0.6), label: L10n.text("insights_comfortable"))
                legendDot(color: Color(red: 1.0, green: 0.45, blue: 0.45), label: L10n.text("insights_uncomfortable"))
                legendDot(color: Color.white.opacity(0.2), label: L10n.text("insights_score_breakdown"))
            }
        }
        .padding(18)
        .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }
}

// MARK: - Animated Bar

struct AnimatedBar: View {
    let height: CGFloat
    let color: Color
    var delay: Double = 0

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(height: appeared ? height : 4)
                .animation(
                    reduceMotion ? nil : AppTheme.cardSpring.delay(delay),
                    value: appeared
                )
        }
        .onAppear { appeared = true }
    }
}
