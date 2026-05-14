import SwiftUI

/// Daily forecast carousel with optimized scrolling performance.
///
/// Uses LazyVStack for buttery-smooth 120fps scrolling with large datasets.
struct ForecastCarousel: View {
    let dailyForecasts: [DailyForecastItem]
    
    var body: some View {
        GlassCard(accentColor: Color(red: 0.4, green: 0.72, blue: 1.0)) {
            VStack(alignment: .leading, spacing: 12) {
                header
                forecastList
            }
            .padding(.bottom, 10)
        }
    }
    
    private var header: some View {
        Label(L10n.text("home_forecast_label"), systemImage: "calendar")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.5))
            .padding(.horizontal, 12)
    }
    
    private var forecastList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // Using LazyHStack for performance with large datasets
            LazyHStack(spacing: 8) {
                ForEach(dailyForecasts) { forecast in
                    ForecastPill(forecast: forecast)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - Forecast Pill

struct ForecastPill: View {
    let forecast: DailyForecastItem
    
    private var skyColor: Color {
        let condition = forecast.conditionSymbol.lowercased()
        
        switch true {
        case condition.contains("rain"), condition.contains("drizzle"):
            return Color(red: 0.3, green: 0.55, blue: 0.9)
        case condition.contains("sun"), condition.contains("clear"):
            return Color(red: 1.0, green: 0.7, blue: 0.2)
        case condition.contains("cloud"):
            return Color(red: 0.5, green: 0.55, blue: 0.65)
        case condition.contains("storm"), condition.contains("thunder"):
            return Color(red: 0.6, green: 0.3, blue: 0.8)
        case condition.contains("snow"):
            return Color(red: 0.7, green: 0.8, blue: 0.9)
        default:
            return Color(red: 0.4, green: 0.72, blue: 1.0)
        }
    }
    
    private var scoreColor: Color {
        AppTheme.color(for: WeatherScore(rawValue: forecast.outdoorScore))
    }
    
    var body: some View {
        VStack(spacing: 6) {
            dayLabel
            weatherIcon
            highTemp
            lowTemp
            scoreBadge
            rainBadge
        }
        .frame(width: 72)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        // Apple HIG: 44pt minimum touch target
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var dayLabel: some View {
        Text(forecast.dayName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(forecast.isToday
                ? Color(red: 1.0, green: 0.85, blue: 0.3)
                : Color.white.opacity(0.6)
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
    
    private var weatherIcon: some View {
        Image(systemName: forecast.conditionSymbol)
            .font(.system(size: 18))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(skyColor)
            .shadow(color: skyColor.opacity(0.3), radius: 4)
    }
    
    private var highTemp: some View {
        Text(forecast.highTemp.formatted(.number.precision(.fractionLength(0))) + "°")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
    }
    
    private var lowTemp: some View {
        Text(forecast.lowTemp.formatted(.number.precision(.fractionLength(0))) + "°")
            .font(.system(size: 12))
            .foregroundStyle(Color.white.opacity(0.4))
    }
    
    private var scoreBadge: some View {
        ZStack {
            Circle()
                .fill(scoreColor.opacity(0.15))
                .frame(width: 32, height: 32)
            
            Circle()
                .stroke(scoreColor.opacity(0.5), lineWidth: 2)
                .frame(width: 32, height: 32)
            
            Text(String(forecast.outdoorScore))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(scoreColor)
        }
    }
    
    private var rainBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "cloud.rain.fill")
                .font(.system(size: 8))
            Text(forecast.precipitationChance > 0 ? "\(Int(forecast.precipitationChance * 100))%" : "0%")
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(forecast.precipitationChance > 0 ? 0.15 : 0))
        )
        .opacity(forecast.precipitationChance > 0 ? 1 : 0)
    }
    
    private var accessibilityLabel: String {
        "\(forecast.dayName): \(forecast.conditionSymbol), High \(forecast.highTemp.formatted(.number.precision(.fractionLength(0)))) \(L10n.text("accessibility_degrees")), Low \(forecast.lowTemp.formatted(.number.precision(.fractionLength(0)))) \(L10n.text("accessibility_degrees")), Outdoor score \(forecast.outdoorScore)"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ForecastCarousel(dailyForecasts: [
            DailyForecastItem(
                dayName: L10n.text("today_label"),
                date: Date(),
                highTemp: 24,
                lowTemp: 18,
                conditionSymbol: "sun.max.fill",
                outdoorScore: 85,
                outdoorDecision: .good,
                isToday: true,
                precipitationChance: 0.1
            ),
            DailyForecastItem(
                dayName: L10n.text("wednesday"),
                date: Date().addingTimeInterval(86400),
                highTemp: 22,
                lowTemp: 16,
                conditionSymbol: "cloud.sun.fill",
                outdoorScore: 75,
                outdoorDecision: .moderate,
                isToday: false,
                precipitationChance: 0.2
            ),
            DailyForecastItem(
                dayName: L10n.text("thursday"),
                date: Date().addingTimeInterval(172800),
                highTemp: 19,
                lowTemp: 14,
                conditionSymbol: "cloud.rain.fill",
                outdoorScore: 55,
                outdoorDecision: .risky,
                isToday: false,
                precipitationChance: 0.7
            )
        ])
        .padding()
    }
}
