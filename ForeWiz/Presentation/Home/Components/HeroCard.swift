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
            HStack(alignment: .top, spacing: 16) {
                // Left: Assistant header + compact summary
                VStack(alignment: .leading, spacing: 8) {
                    // Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 5, height: 5)
                        Text(L10n.text("home_assistant_badge"))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                            .lineLimit(1)
                    }

                    // Headline — concise
                    Text(assistant.headline)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    // Summary — compact
                    Text(assistant.summary)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineSpacing(1)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: Score ring
                ScoreRingView(score: WeatherScore(rawValue: score), size: 48, lineWidth: 3.5)
                    .frame(width: 48, height: 48)
            }

            Divider()
                .frame(height: 1)
                .overlay(.white.opacity(0.06))
                .padding(.vertical, 4)

            // Bottom: temperature + compact metrics
            HStack(alignment: .center, spacing: 12) {
                // Temperature — large, prominent
                VStack(alignment: .leading, spacing: 1) {
                    Text(weather.temperatureText)
                        .font(.system(size: 36, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(weather.conditionText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }
                .frame(minWidth: 60, alignment: .leading)

                Spacer(minLength: 4)

                // Compact metrics: feels·high/low·humidity·sunrise/set
                HStack(spacing: 6) {
                    CompactChip(
                        icon: "thermometer.medium",
                        value: weather.feelsLikeText
                            .replacingOccurrences(of: L10n.text("weather_feels_like") + " ", with: ""),
                        color: .white
                    )
                    Divider().frame(width: 1, height: 14).overlay(.white.opacity(0.08))

                    HStack(spacing: 1) {
                        if weather.highTempText != "–" {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundStyle(AppTheme.sunshine)
                            Text(weather.highTempText)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        if weather.lowTempText != "–" {
                            Text("·").foregroundStyle(.white.opacity(0.3))
                            Image(systemName: "arrow.down")
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundStyle(AppTheme.sky)
                            Text(weather.lowTempText)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    Divider().frame(width: 1, height: 14).overlay(.white.opacity(0.08))

                    CompactChip(
                        icon: "humidity.fill",
                        value: weather.humidityText,
                        color: AppTheme.sky
                    )

                    if weather.sunriseText != nil || weather.sunsetText != nil {
                        Divider().frame(width: 1, height: 14).overlay(.white.opacity(0.08))

                        HStack(spacing: 4) {
                            if let sunrise = weather.sunriseText {
                                Image(systemName: "sunrise.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.sunshine)
                                Text(sunrise)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            if weather.sunriseText != nil && weather.sunsetText != nil {
                                Text("·").foregroundStyle(.white.opacity(0.2))
                            }
                            if let sunset = weather.sunsetText {
                                Image(systemName: "sunset.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.ember)
                                Text(sunset)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
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

