import SwiftUI
import Charts

struct WeatherInsightsView: View {
    let snapshot: WeatherSnapshot
    let recommendation: DailyRecommendation

    @State private var selectedMetric: MetricType = .temperature
    @State private var selectedTimeRange: TimeRange = .today
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                metricSelector

                timeRangeSelector

                chartSection

                statisticsSection

                trendsSection

                comfortAnalysisSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(L10n.text("insights_title"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }

    private var metricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MetricType.allCases) { metric in
                    MetricButton(
                        metric: metric,
                        isSelected: selectedMetric == metric
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMetric = metric
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.localizedTitle)
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(selectedMetric.localizedTitle)
                    .font(.headline)

                Spacer()

                Text(selectedMetric.currentValue(from: snapshot))
                    .font(.title2.bold())
                    .foregroundStyle(selectedMetric.color)
            }

            chartView
                .frame(height: 200)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    @ViewBuilder
    private var chartView: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(chartData, id: \.hour) { point in
                    LineMark(
                        x: .value("Hour", point.hour),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(selectedMetric.color)

                    AreaMark(
                        x: .value("Hour", point.hour),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(selectedMetric.color.opacity(0.1))
                }

                if let currentHour = Calendar.current.component(.hour, from: Date()) as Int?,
                   let currentValue = chartData.first(where: { $0.hour == currentHour })?.value {
                    RuleMark(x: .value("Now", currentHour))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(.gray)
                }
            }
            .chartYScale(domain: chartYRange)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour):00")
                                .font(.caption)
                        }
                    }
                }
            }
        } else {
            LegacyChartView(data: chartData, color: selectedMetric.color)
                .frame(height: 200)
        }
    }

    private var chartData: [ChartDataPoint] {
        let hourly = snapshot.hourly
        let calendar = Calendar.current
        let now = Date()

        return hourly
            .filter { point in
                switch selectedTimeRange {
                case .today:
                    return calendar.isDate(point.date, inSameDayAs: now)
                case .next24Hours:
                    return point.date >= now && point.date <= now.addingTimeInterval(24 * 3600)
                case .tomorrow:
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
                    return calendar.isDate(point.date, inSameDayAs: tomorrow)
                }
            }
            .enumerated()
            .map { index, point in
                let hour = calendar.component(.hour, from: point.date)
                let value = selectedMetric.value(from: point)
                return ChartDataPoint(hour: hour, value: value, index: index)
            }
    }

    private var chartYRange: ClosedRange<Double> {
        let values = chartData.map(\.value)
        guard let min = values.min(), let max = values.max() else {
            return 0...100
        }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("insights_statistics"))
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatisticCard(
                    title: L10n.text("insights_high"),
                    value: String(format: "%.1f", chartData.map(\.value).max() ?? 0),
                    unit: selectedMetric.unit,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )

                StatisticCard(
                    title: L10n.text("insights_low"),
                    value: String(format: "%.1f", chartData.map(\.value).min() ?? 0),
                    unit: selectedMetric.unit,
                    icon: "arrow.down.circle.fill",
                    color: .blue
                )

                StatisticCard(
                    title: L10n.text("insights_average"),
                    value: String(format: "%.1f", chartData.map(\.value).reduce(0, +) / Double(max(1, chartData.count))),
                    unit: selectedMetric.unit,
                    icon: "minus.circle.fill",
                    color: .orange
                )

                StatisticCard(
                    title: L10n.text("insights_range"),
                    value: String(format: "%.1f", (chartData.map(\.value).max() ?? 0) - (chartData.map(\.value).min() ?? 0)),
                    unit: selectedMetric.unit,
                    icon: "arrow.left.arrow.right.circle.fill",
                    color: .purple
                )
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("insights_trends"))
                .font(.headline)

            VStack(spacing: 12) {
                TrendRow(
                    title: L10n.text("insights_temp_trend"),
                    trend: calculateTempTrend(),
                    icon: "thermometer"
                )

                TrendRow(
                    title: L10n.text("insights_comfort_trend"),
                    trend: calculateComfortTrend(),
                    icon: "face.smiling"
                )

                TrendRow(
                    title: L10n.text("insights_precipitation_risk"),
                    trend: calculatePrecipitationRisk(),
                    icon: "cloud.rain"
                )
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private var comfortAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("insights_comfort_analysis"))
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(comfortWindows, id: \.startHour) { window in
                    ComfortWindowRow(window: window)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private var comfortWindows: [ComfortWindow] {
        let hourly = snapshot.hourly
        let calendar = Calendar.current

        return hourly
            .map { point -> ComfortWindow? in
                let hour = calendar.component(.hour, from: point.date)
                let score = calculateComfortScore(for: point)
                let level: ComfortLevel

                switch score {
                case 80...100: level = .excellent
                case 60..<80: level = .good
                case 40..<60: level = .moderate
                default: level = .poor
                }

                return ComfortWindow(startHour: hour, score: score, level: level)
            }
            .compactMap { $0 }
            .reduce(into: []) { result, window in
                if let last = result.last, last.level == window.level {
                    result[result.count - 1] = ComfortWindow(
                        startHour: last.startHour,
                        endHour: window.startHour,
                        score: (last.score + window.score) / 2,
                        level: last.level
                    )
                } else {
                    result.append(window)
                }
            }
    }

    private func calculateComfortScore(for point: HourlyWeatherPoint) -> Int {
        var score = 100

        let temp = point.apparentTemperatureCelsius
        if temp < 10 || temp > 35 {
            score -= 30
        } else if temp < 15 || temp > 30 {
            score -= 15
        }

        if let precip = point.precipitationChance, precip > 0.3 {
            score -= Int(precip * 30)
        }

        if let windSpeed = point.windSpeedKph, windSpeed > 30 {
            score -= 20
        }

        if let uv = point.uvIndex, uv > 8 {
            score -= 15
        }

        return max(0, score)
    }

    private func calculateTempTrend() -> Trend {
        let values = chartData.map(\.value)
        guard values.count > 1 else { return .stable }

        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))

        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

        let diff = secondAvg - firstAvg
        if diff > 2 { return .rising }
        if diff < -2 { return .falling }
        return .stable
    }

    private func calculateComfortTrend() -> Trend {
        let windows = comfortWindows
        guard windows.count > 1 else { return .stable }

        let first = windows.first?.score ?? 50
        let last = windows.last?.score ?? 50

        if last > first + 10 { return .rising }
        if last < first - 10 { return .falling }
        return .stable
    }

    private func calculatePrecipitationRisk() -> Trend {
        let risk = snapshot.hourly
            .compactMap { $0.precipitationChance }
            .max() ?? 0

        if risk > 0.6 { return .rising }
        if risk > 0.3 { return .stable }
        return .falling
    }
}

enum MetricType: String, CaseIterable, Identifiable {
    case temperature, humidity, wind, uvIndex, precipitation

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .temperature: return L10n.text("metric_temperature")
        case .humidity: return L10n.text("metric_humidity")
        case .wind: return L10n.text("metric_wind")
        case .uvIndex: return L10n.text("metric_uv")
        case .precipitation: return L10n.text("metric_precipitation")
        }
    }

    var unit: String {
        switch self {
        case .temperature: return "°C"
        case .humidity: return "%"
        case .wind: return "km/h"
        case .uvIndex: return ""
        case .precipitation: return "%"
        }
    }

    var color: Color {
        switch self {
        case .temperature: return .orange
        case .humidity: return .blue
        case .wind: return .cyan
        case .uvIndex: return .purple
        case .precipitation: return .indigo
        }
    }

    func value(from point: HourlyWeatherPoint) -> Double {
        switch self {
        case .temperature: return point.apparentTemperatureCelsius
        case .humidity: return (point.humidity ?? 0) * 100
        case .wind: return point.windSpeedKph ?? 0
        case .uvIndex: return Double(point.uvIndex ?? 0)
        case .precipitation: return (point.precipitationChance ?? 0) * 100
        }
    }

    func currentValue(from snapshot: WeatherSnapshot) -> String {
        let current = snapshot.current
        switch self {
        case .temperature: return "\(Int(current.apparentTemperatureCelsius))°C"
        case .humidity: return "\(Int((current.humidity ?? 0) * 100))%"
        case .wind: return "\(Int(current.windSpeedKph ?? 0)) km/h"
        case .uvIndex: return "\(current.uvIndex ?? 0)"
        case .precipitation: return "\(Int((current.precipitationChance ?? 0) * 100))%"
        }
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case today, next24Hours, tomorrow

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .today: return L10n.text("range_today")
        case .next24Hours: return L10n.text("range_24h")
        case .tomorrow: return L10n.text("range_tomorrow")
        }
    }
}

enum Trend {
    case rising, falling, stable

    var icon: String {
        switch self {
        case .rising: return "arrow.up"
        case .falling: return "arrow.down"
        case .stable: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .rising: return .green
        case .falling: return .red
        case .stable: return .orange
        }
    }

    var description: String {
        switch self {
        case .rising: return L10n.text("trend_increasing")
        case .falling: return L10n.text("trend_decreasing")
        case .stable: return L10n.text("trend_stable")
        }
    }
}

enum ComfortLevel {
    case excellent, good, moderate, poor

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .moderate: return .orange
        case .poor: return .red
        }
    }

    var description: String {
        switch self {
        case .excellent: return L10n.text("comfort_excellent")
        case .good: return L10n.text("comfort_good")
        case .moderate: return L10n.text("comfort_moderate")
        case .poor: return L10n.text("comfort_poor")
        }
    }
}

struct ChartDataPoint {
    let hour: Int
    let value: Double
    let index: Int
}

struct ComfortWindow {
    let startHour: Int
    var endHour: Int?
    let score: Int
    let level: ComfortLevel

    init(startHour: Int, endHour: Int? = nil, score: Int, level: ComfortLevel) {
        self.startHour = startHour
        self.endHour = endHour
        self.score = score
        self.level = level
    }
}

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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? metric.color : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: isSelected ? metric.color.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
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
                Text("\(value)\(unit)")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

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

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                Text(trend.description)
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

struct ComfortWindowRow: View {
    let window: ComfortWindow

    var body: some View {
        HStack {
            let startText = String(format: "%02d:00", window.startHour)
            let endText = window.endHour.map { String(format: "%02d:00", $0) } ?? "..."

            Text("\(startText) - \(endText)")
                .font(.subheadline)
                .monospacedDigit()

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(window.level.color)
                    .frame(width: 8, height: 8)

                Text(window.level.description)
                    .font(.caption)
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
