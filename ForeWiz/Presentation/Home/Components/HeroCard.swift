import SwiftUI

// MARK: - Hero Card

struct HeroCard: View {
    let assistant: HomeAssistantViewState
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation

    private var accentColor: Color { AppTheme.toneColor(for: assistant.tone) }

    var body: some View {
        LiquidGlassCard(accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: Headline + Temperature
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    // Headline
                    Text(assistant.headline)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.85)
                        .layoutPriority(1)

                    Spacer(minLength: 4)

                    // Temperature + condition
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(weather.temperatureText)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(weather.conditionText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                // MARK: Summary
                Text(assistant.summary)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                // MARK: Metrics Row
                FlowLayout(spacing: 8) {
                    // Feels like
                    MetricPill(
                        icon: "thermometer.medium",
                        label: L10n.text("weather_feels_like"),
                        value: weather.feelsLikeText
                            .replacingOccurrences(of: L10n.text("weather_feels_like") + " ", with: ""),
                        color: .white
                    )

                    // High
                    if weather.highTempText != "-" {
                        MetricPill(
                            icon: "arrow.up",
                            label: L10n.text("weather_high"),
                            value: weather.highTempText,
                            color: AppTheme.sunshine
                        )
                    }

                    // Low
                    if weather.lowTempText != "-" {
                        MetricPill(
                            icon: "arrow.down",
                            label: L10n.text("weather_low"),
                            value: weather.lowTempText,
                            color: AppTheme.sky
                        )
                    }

                    // Humidity
                    if weather.humidityText != "-" {
                        MetricPill(
                            icon: "humidity.fill",
                            label: L10n.text("weather_humidity"),
                            value: weather.humidityText,
                            color: AppTheme.sky
                        )
                    }
                }

                // MARK: Sunrise/Sunset
                if weather.sunriseText != nil || weather.sunsetText != nil {
                    HStack(spacing: 12) {
                        if let sunrise = weather.sunriseText {
                            SunPill(
                                icon: "sunrise.fill",
                                color: AppTheme.sunshine,
                                time: sunrise
                            )
                        }
                        if let sunset = weather.sunsetText {
                            SunPill(
                                icon: "sunset.fill",
                                color: AppTheme.ember,
                                time: sunset
                            )
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.formatted("accessibility_hero_weather_template", weather.temperatureText, weather.conditionText, assistant.headline))
    }
}

// MARK: - Metric Pill

private struct MetricPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    init(icon: String, label: String, value: String, color: Color) {
        self.icon = icon
        self.label = label
        self.value = value
        self.color = color
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color.opacity(0.8))
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 0.5)
        )
    }
}

// MARK: - Sun Pill

private struct SunPill: View {
    let icon: String
    let color: Color
    let time: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(time)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 0.5)
        )
    }
}
