import SwiftUI

// MARK: - Hero Card

struct HeroCard: View {
    let assistant: HomeAssistantViewState
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation

    private var accentColor: Color { AppTheme.toneColor(for: assistant.tone) }
    private var score: Int { recommendation.outdoorScore.rawValue }

    var body: some View {
        LiquidGlassCard(accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 14) {
                // Assistant Header
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 6, height: 6)
                            Text(L10n.text("home_assistant_badge"))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.8)
                                .foregroundStyle(accentColor)
                                .lineLimit(1)
                        }

                        // Headline
                        Text(assistant.headline)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.85)

                        // Summary
                        Text(assistant.summary)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)

                    Spacer()

                    ScoreRingView(score: WeatherScore(rawValue: score), size: 56, lineWidth: 4)
                        .frame(width: 56, height: 56)
                }

                // Weather Metrics with Sunrise/Sunset
                VStack(spacing: 12) {
                    // Top row: Temperature + Metrics
                    HStack(alignment: .center, spacing: 8) {
                        // Temperature
                        VStack(alignment: .leading, spacing: 2) {
                            Text(weather.temperatureText)
                                .font(.system(size: 42, weight: .thin, design: .rounded))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                            Text(weather.conditionText)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(2)
                        }
                        .frame(minWidth: 70, alignment: .leading)

                        Spacer(minLength: 4)

                        // Metric cells grid
                        HStack(spacing: 0) {
                            MetricCell(icon: "thermometer.medium", value: weather.feelsLikeText
                                .replacingOccurrences(of: L10n.text("weather_feels_like") + " ", with: ""), label: L10n.text("home_metric_feels"))
                                .frame(maxWidth: .infinity)
                            if weather.highTempText != "–" {
                                MetricCell(icon: "arrow.up", value: weather.highTempText, label: L10n.text("home_metric_high"))
                                    .frame(maxWidth: .infinity)
                            }
                            if weather.lowTempText != "–" {
                                MetricCell(icon: "arrow.down", value: weather.lowTempText, label: L10n.text("home_metric_low"))
                                    .frame(maxWidth: .infinity)
                            }
                            MetricCell(icon: "humidity.fill", value: weather.humidityText, label: L10n.text("home_metric_humidity"))
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Sunrise/Sunset row
                    HStack(spacing: 16) {
                        SunTimeRow(
                            icon: "sunrise.fill",
                            color: AppTheme.sunshine,
                            time: weather.sunriseText ?? L10n.text("home_sunrise_unavailable"),
                            label: L10n.text("home_sunrise_label")
                        )
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(width: 1, height: 24)
                            .overlay(.white.opacity(0.1))

                        SunTimeRow(
                            icon: "sunset.fill",
                            color: AppTheme.ember,
                            time: weather.sunsetText ?? L10n.text("home_sunset_unavailable"),
                            label: L10n.text("home_sunset_label")
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(10)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.formatted("accessibility_hero_weather_template", weather.temperatureText, weather.conditionText, assistant.headline))
    }
}

// MARK: - Metric Cell

struct MetricCell: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .lineLimit(1)
        }
        .frame(minWidth: 54)
    }
}

// MARK: - Sun Time Row

struct SunTimeRow: View {
    let icon: String
    let color: Color
    let time: String
    let label: String

    init(icon: String, color: Color, time: String, label: String = "") {
        self.icon = icon
        self.color = color
        self.time = time
        self.label = label
    }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineLimit(1)
                Text(time)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
    }
}
