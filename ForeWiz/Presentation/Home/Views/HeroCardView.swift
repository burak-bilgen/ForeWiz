import SwiftUI

/// The unified hero card displaying weather summary and AI assistant status.
///
/// Extracted from HomeView.swift to reduce file size and improve testability.
/// Features glass morphism design, animated icons, and weather-aware gradients.
struct HeroCardView: View {
    let assistant: HomeAssistantViewState
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation
    let isUsingCachedWeather: Bool
    let onPrimaryAction: () -> Void
    
    @State private var iconPulse = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var accentColor: Color { AppTheme.toneColor(for: assistant.tone) }
    private var decisionColor: Color { AppTheme.color(for: recommendation.outdoorDecision) }
    
    var body: some View {
        GlassCard(accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                weatherMetricsSection
                sunriseSunsetSection
            }
            .padding(14)
        }
        .onAppear { triggerIconPulse() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                assistantBadge
                headline
                summary
            }
            .layoutPriority(1)
            
            decisionIcon
        }
    }
    
    private var assistantBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .bold))
            Text(L10n.text("home_assistant_badge"))
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(accentColor)
        .textCase(.uppercase)
    }
    
    private var headline: some View {
        Text(assistant.headline)
            .font(.system(size: 25, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.85)
    }
    
    private var summary: some View {
        Text(assistant.summary)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.68))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var decisionIcon: some View {
        ZStack {
            Circle()
                .fill(decisionColor.opacity(0.15))
                .frame(width: 60, height: 60)
                .scaleEffect(iconPulse ? 1.08 : 1.0)
            
            Image(systemName: assistant.symbolName)
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(decisionColor)
                .symbolEffect(.pulse, options: .speed(0.5), value: iconPulse)
        }
    }
    
    private var weatherMetricsSection: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                temperatureDisplay
                conditionDisplay
            }
            .frame(minWidth: 78, alignment: .leading)
            
            Spacer()
            
            feelsLikeMetric
            
            if weather.highTempText != "–" {
                highTempMetric
            }
            
            if weather.lowTempText != "–" {
                lowTempMetric
            }
            
            humidityMetric
        }
    }
    
    private var temperatureDisplay: some View {
        Text(weather.temperatureText)
            .font(.system(size: 38, weight: .thin, design: .rounded))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.6)
            .accessibilityLabel(L10n.formatted("home.accessibility.temperature", weather.temperatureText))
    }
    
    private var conditionDisplay: some View {
        Text(weather.conditionText)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.55))
            .lineLimit(2)
            .accessibilityLabel(L10n.formatted("home.accessibility.condition", weather.conditionText))
    }
    
    private var feelsLikeMetric: some View {
        MetricInlineView(
            icon: "thermometer.medium",
            label: L10n.text("feels_like_short"),
            value: feelsLikeValue
        )
    }
    
    private var feelsLikeValue: String {
        weather.feelsLikeText.replacingOccurrences(of: L10n.text("weather_feels_like") + " ", with: "")
    }
    
    private var highTempMetric: some View {
        MetricInlineView(
            icon: "arrow.up",
            label: L10n.text("high_label"),
            value: weather.highTempText
        )
    }
    
    private var lowTempMetric: some View {
        MetricInlineView(
            icon: "arrow.down",
            label: L10n.text("low_label"),
            value: weather.lowTempText
        )
    }
    
    private var humidityMetric: some View {
        MetricInlineView(
            icon: "humidity.fill",
            label: L10n.text("humidity"),
            value: weather.humidityText
        )
    }
    
    private var sunriseSunsetSection: some View {
        Group {
            if weather.sunriseText != nil || weather.sunsetText != nil {
                HStack(spacing: 12) {
                    if let sunrise = weather.sunriseText {
                        SunriseView(time: sunrise)
                    }
                    
                    if weather.sunriseText != nil, weather.sunsetText != nil {
                        Spacer()
                    }
                    
                    if let sunset = weather.sunsetText {
                        SunsetView(time: sunset)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        L10n.formatted("home.accessibility.summary", weather.temperatureText, weather.conditionText, assistant.headline)
    }
    
    // MARK: - Animation
    
    private func triggerIconPulse() {
        guard !reduceMotion else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconPulse = true
        }
        
        // Auto-reset for continuous subtle animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                iconPulse = false
            }
        }
    }
}

// MARK: - Subviews

private struct MetricInlineView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.35))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(minWidth: 44)
        // Apple HIG: Ensure minimum touch target for VoiceOver
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

private struct SunriseView: View {
    let time: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.3))
            
            Text(time)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .accessibilityLabel("Sunrise at \(time)")
    }
}

private struct SunsetView: View {
    let time: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sunset.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.2))
            
            Text(time)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .accessibilityLabel("Sunset at \(time)")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        HeroCardView(
            assistant: HomeAssistantViewState(
                headline: "Clear outdoor day",
                summary: "Perfect conditions for outdoor activities",
                primaryActionTitle: "Best Window",
                primaryActionDetail: "14:00 - 16:00",
                symbolName: "checkmark.seal.fill",
                tone: .good,
                criticalAlert: nil
            ),
            weather: HomeCurrentWeatherViewState(
                temperatureText: "24°",
                feelsLikeText: "Feels like 26°",
                conditionText: "Clear",
                symbolName: "sun.max.fill",
                humidityText: "65%",
                windText: "12 km/h",
                uvIndexText: "6",
                highTempText: "28°",
                lowTempText: "18°",
                sunriseText: "06:42",
                sunsetText: "19:28"
            ),
            recommendation: DailyRecommendation(
                generatedAt: Date(),
                outdoorDecision: .good,
                outdoorScore: WeatherScore(rawValue: 85),
                bestOutdoorWindow: nil,
                bestActivityWindows: [],
                avoidWindows: [],
                outfit: OutfitRecommendation(title: "Light layers", items: ["T-shirt", "Light jacket"], accessories: [], warning: nil),
                risks: [],
                summaryText: "Great weather for outdoor activities",
                explanation: "85/100",
                isTomorrowsRecommendation: false
            ),
            isUsingCachedWeather: false,
            onPrimaryAction: {}
        )
        .padding()
    }
}
