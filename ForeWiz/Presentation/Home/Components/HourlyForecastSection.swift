import SwiftUI

// MARK: - Hourly Forecast Section

struct HourlyForecastSection: View {
    let hourlyScores: [HourlyScoreItem]

    var body: some View {
        LiquidGlassCard(accentColor: AppTheme.royalPurple) {
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.text("home_hourly_label"), systemImage: "clock.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)

                if !hourlyScores.isEmpty {
                    TemperatureTrendChart(hourlyScores: hourlyScores)
                        .frame(height: 130)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(hourlyScores) { item in
                            HourlyPill(item: item)
                                .fixedSize()
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .scrollClipDisabled()
                .padding(.horizontal, -8)
            }
        }
    }
}

// MARK: - Hourly Pill

struct HourlyPill: View {
    let item: HourlyScoreItem

    private var scoreColor: Color {
        switch item.score {
        case 70...100: AppTheme.success
        case 40..<70: AppTheme.warning
        default: AppTheme.danger
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(String(format: "%02d", item.hour))\(L10n.text("time_format_hour"))")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)

            Image(systemName: item.symbolName)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))

            Text(item.temperatureText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            RoundedRectangle(cornerRadius: 2)
                .fill(scoreColor)
                .frame(width: 16, height: 3)

            Text(String(format: "%.1f", Double(item.score) / 10.0))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Temperature Trend Chart

struct TemperatureTrendChart: View {
    let hourlyScores: [HourlyScoreItem]

    var body: some View {
        let slots = hourlyScores.prefix(12)
        let temps = slots.map { extractTemp($0.temperatureText) }
        let minTemp = floor(temps.min() ?? 0)
        let maxTemp = ceil(temps.max() ?? 1)
        let tempRange = max(maxTemp - minTemp, 3)

        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, item in
                let temp = temps[safe: index] ?? 0
                let ratio = (temp - minTemp) / tempRange
                let barHeight = max(ratio * 80, 4)

                VStack(spacing: 3) {
                    Text(item.temperatureText)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(barColor(for: temp))
                        .frame(width: 12, height: barHeight)

                    Text(String(format: "%02d", item.hour))
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    private func barColor(for temp: CGFloat) -> Color {
        switch temp {
        case 30...: return AppTheme.danger
        case 20..<30: return AppTheme.warning
        case 10..<20: return AppTheme.success
        default: return AppTheme.sky
        }
    }

    private func extractTemp(_ text: String) -> CGFloat {
        let clean = text.replacingOccurrences(of: L10n.text("unit_degree"), with: "")
            .replacingOccurrences(of: "°", with: "")
            .trimmingCharacters(in: .whitespaces)
        return CGFloat(Double(clean) ?? 0)
    }
}
