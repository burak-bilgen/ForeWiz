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
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .safeAreaPadding(.bottom, 12)
        .navigationTitle(L10n.text("insights_title"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Metric Selector

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

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        Picker(L10n.text("insights_time_range"), selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.localizedTitle)
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Chart Section

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    chartTitle
                    Spacer(minLength: 12)
                    chartValue
                }
                VStack(alignment: .leading, spacing: 4) {
                    chartTitle
                    chartValue
                }
            }

            chartView
                .frame(height: 200)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chartTitle: some View {
        Text(selectedMetric.localizedTitle)
            .font(.headline)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var chartValue: some View {
        Text(selectedMetric.currentValue(from: snapshot))
            .font(.title2.bold())
            .foregroundStyle(selectedMetric.color)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    @ViewBuilder
    private var chartView: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(chartData, id: \.hour) { point in
                    LineMark(
                        x: .value(L10n.text("chart_axis_hour"), point.hour),
                        y: .value(L10n.text("chart_axis_value"), point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(selectedMetric.color)

                    AreaMark(
                        x: .value(L10n.text("chart_axis_hour"), point.hour),
                        y: .value(L10n.text("chart_axis_value"), point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(selectedMetric.color.opacity(0.1))
                }

                let currentHour = Calendar.current.component(.hour, from: Date())
                if chartData.contains(where: { $0.hour == currentHour }) {
                    RuleMark(x: .value(L10n.text("chart_now_label"), currentHour))
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
                            Text(L10n.formatted("time_format_full", hour))
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
                    guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
                        return false
                    }
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

    // MARK: - Statistics Section

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
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Trends Section

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
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Comfort Analysis Section

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
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Computed

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

// MARK: - Preview

#Preview {
    let rec = PreviewWeatherFactory.dailyRecommendation()
    let snapshot = WeatherSnapshot(
        location: LocationCoordinate(latitude: 41.0082, longitude: 28.9784),
        current: CurrentWeatherPoint(
            date: Date(),
            temperatureCelsius: 24,
            apparentTemperatureCelsius: 25,
            humidity: 0.55,
            windSpeedKph: 14,
            precipitationChance: 0.12,
            precipitationAmountMm: 0,
            uvIndex: 3,
            conditionCode: "partlyCloudy",
            isDaylight: true,
            severeWeatherRisk: nil
        ),
        hourly: [],
        daily: [],
        fetchedAt: Date(),
        attribution: nil
    )
    WeatherInsightsView(
        snapshot: snapshot,
        recommendation: rec
    )
}
