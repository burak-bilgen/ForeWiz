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
        }
        .padding(.horizontal, 10)
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
    
    private var accessibilityLabel: String {
        "\(forecast.dayName): \(forecast.conditionSymbol), High \(forecast.highTemp.formatted(.number.precision(.fractionLength(0)))) degrees, Low \(forecast.lowTemp.formatted(.number.precision(.fractionLength(0)))) degrees, Outdoor score \(forecast.outdoorScore)"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ForecastCarousel(dailyForecasts: [
            DailyForecastItem(
                dayName: "Today",
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
                dayName: "Wed",
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
                dayName: "Thu",
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
