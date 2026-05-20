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

                // Weather Metrics — compact layout
                VStack(spacing: 10) {
                    // Temperature + compact metrics row
                    HStack(alignment: .center, spacing: 12) {
                        // Temperature — large, prominent
                        VStack(alignment: .leading, spacing: 1) {
                            Text(weather.temperatureText)
                                .font(.system(size: 40, weight: .thin, design: .rounded))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                            Text(weather.conditionText)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                                .lineLimit(1)
                        }
                        .frame(minWidth: 65, alignment: .leading)

                        Spacer(minLength: 4)

                        // Compact metric chips: high·low · humidity · feels-like
                        HStack(spacing: 8) {
                            // Feels like
                            CompactChip(
                                icon: "thermometer.medium",
                                value: weather.feelsLikeText
                                    .replacingOccurrences(of: L10n.text("weather_feels_like") + " ", with: ""),
                                color: .white
                            )

                            Divider().frame(width: 1, height: 16).overlay(.white.opacity(0.1))

                            // High/Low merged
                            HStack(spacing: 2) {
                                if weather.highTempText != "–" {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundStyle(AppTheme.sunshine)
                                    Text(weather.highTempText)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                if weather.lowTempText != "–" {
                                    Text("·")
                                        .foregroundStyle(.white.opacity(0.3))
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundStyle(AppTheme.sky)
                                    Text(weather.lowTempText)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                            }

                            Divider().frame(width: 1, height: 16).overlay(.white.opacity(0.1))

                            // Humidity
                            CompactChip(
                                icon: "humidity.fill",
                                value: weather.humidityText,
                                color: AppTheme.sky
                            )
                        }
                    }

                    // Sunrise/Sunset — compact inline
                    if weather.sunriseText != nil || weather.sunsetText != nil {
                        HStack(spacing: 12) {
                            SunTimeBadge(
                                icon: "sunrise.fill",
                                color: AppTheme.sunshine,
                                time: weather.sunriseText ?? "–"
                            )
                            Text("·")
                                .foregroundStyle(.white.opacity(0.2))
                            SunTimeBadge(
                                icon: "sunset.fill",
                                color: AppTheme.ember,
                                time: weather.sunsetText ?? "–"
                            )
                        }
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.formatted("accessibility_hero_weather_template", weather.temperatureText, weather.conditionText, assistant.headline))
    }
}

// MARK: - Compact Chip

private struct CompactChip: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color.opacity(0.7))
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

// MARK: - Sun Time Badge

private struct SunTimeBadge: View {
    let icon: String
    let color: Color
    let time: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(time)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
