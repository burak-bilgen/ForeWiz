import SwiftUI

// MARK: - Metric Button

struct MetricButton: View {
    let metric: MetricType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName(for: metric))
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : metric.color)

                Text(metric.localizedTitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? metric.color : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: isSelected ? metric.color.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(.fullTapArea)
    }

    private func iconName(for metric: MetricType) -> String {
        switch metric {
        case .temperature: return "thermometer"
        case .humidity: return "humidity"
        case .wind: return "wind"
        case .uvIndex: return "sun.max"
        case .precipitation: return "cloud.rain"
        }
    }
}

// MARK: - Statistic Card

struct StatisticCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.formatted("%@%@", value, unit))
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Trend Row

struct TrendRow: View {
    let title: String
    let trend: Trend
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                Text(trend.description)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            .font(.caption)
            .foregroundStyle(trend.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(trend.color.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Comfort Window Row

struct ComfortWindowRow: View {
    let window: ComfortWindow

    var body: some View {
        HStack {
            let startText = L10n.formatted("time_format_full", window.startHour)
            let endText = window.endHour.map { L10n.formatted("time_format_full", $0) } ?? L10n.text("time_fallback_end")

            Text("\(startText)\(L10n.text("time_range_separator"))\(endText)")
                .font(.subheadline)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Circle()
                    .fill(window.level.color)
                    .frame(width: 8, height: 8)

                Text(window.level.description)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            .foregroundStyle(window.level.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(window.level.color.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Legacy Chart View (iOS < 16)

struct LegacyChartView: View {
    let data: [ChartDataPoint]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if data.count > 1 {
                    Path { path in
                        let stepX = geometry.size.width / CGFloat(max(1, data.count - 1))
                        let minValue = data.map(\.value).min() ?? 0
                        let maxValue = data.map(\.value).max() ?? 1
                        let range = maxValue - minValue

                        for (index, point) in data.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = range > 0 ? (1 - CGFloat((point.value - minValue) / range)) * geometry.size.height : geometry.size.height / 2

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, lineWidth: 2)

                    ForEach(data, id: \.index) { point in
                        let stepX = geometry.size.width / CGFloat(max(1, data.count - 1))
                        let minValue = data.map(\.value).min() ?? 0
                        let maxValue = data.map(\.value).max() ?? 1
                        let range = maxValue - minValue
                        let x = CGFloat(point.index) * stepX
                        let y = range > 0 ? (1 - CGFloat((point.value - minValue) / range)) * geometry.size.height : geometry.size.height / 2

                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
}
