import SwiftUI

// MARK: - Hero Card

struct HeroCard: View {
    let assistant: HomeAssistantViewState
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation

    private var accentColor: Color { AppTheme.toneColor(for: assistant.tone) }
    private var score: Int { recommendation.outdoorScore.rawValue }
    private var weatherScore: WeatherScore { WeatherScore(rawValue: score) }

    var body: some View {
        LiquidGlassCard(accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: Header — Badge + Headline
                VStack(alignment: .leading, spacing: 8) {
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
                }

                // MARK: Main Row — Temperature + Score Ring
                HStack(alignment: .center, spacing: 16) {
                    // Temperature — large hero element
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weather.temperatureText)
                            .font(.system(size: 52, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text(weather.conditionText)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    // Score Ring — larger & more prominent
                    ScoreRingView(score: weatherScore, size: 68, lineWidth: 5, showOutOf100: false)
                        .frame(width: 68, height: 68)
                }

                // MARK: Summary
                Text(assistant.summary)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                // MARK: Metrics Row — compact pills
                HStack(spacing: 8) {
                    // Feels like
                    MetricPill(
                        icon: "thermometer.medium",
                        value: weather.feelsLikeText
                            .replacingOccurrences(of: L10n.text("weather_feels_like") + " ", with: ""),
                        color: .white
                    )

                    // High / Low
                    if weather.highTempText != "–" {
                        MetricPill(
                            icon: "arrow.up",
                            value: weather.highTempText,
                            color: AppTheme.sunshine
                        )
                    }
                    if weather.lowTempText != "–" {
                        MetricPill(
                            icon: "arrow.down",
                            value: weather.lowTempText,
                            color: AppTheme.sky
                        )
                    }

                    // Humidity
                    if weather.humidityText != "–" {
                        MetricPill(
                            icon: "humidity.fill",
                            value: weather.humidityText,
                            color: AppTheme.sky
                        )
                    }
                }

                // MARK: Sunrise/Sunset — refined pill
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
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color.opacity(0.8))
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
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
