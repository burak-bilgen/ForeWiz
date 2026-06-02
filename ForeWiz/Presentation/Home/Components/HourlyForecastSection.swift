import SwiftUI
import WizPathKit

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
                        .frame(height: 80)
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

    var body: some View {
        VStack(spacing: 4) {
            Text("\(item.hour)\(L10n.text("time_format_hour"))")
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
        // Pad the range on both sides so bars never start from zero height.
        // This prevents dramatic visual cliffs (e.g., 10°C vs 20°C no longer shows 4px vs 80px).
        let rawMin = floor(temps.min() ?? 0)
        let rawMax = ceil(temps.max() ?? 1)
        let paddedMin = floor(rawMin - 5)
        let paddedMax = ceil(rawMax + 5)
        let tempRange = max(paddedMax - paddedMin, 8)

        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, item in
                let temp = temps[safe: index] ?? 0
                let ratio = max((temp - paddedMin) / tempRange, 0.08)
                let barHeight = ratio * 45

                VStack(spacing: 3) {
                    Text(item.temperatureText)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(barColor(for: temp))
                        .frame(width: 18, height: barHeight)

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
