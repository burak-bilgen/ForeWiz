import SwiftUI

/// Hourly forecast view with temperature trend chart.
///
/// Features optimized scrolling and weather condition visualization.
struct HourlyForecastView: View {
    let hourlyScores: [HourlyScoreItem]
    
    var body: some View {
        GlassCard(accentColor: Color(red: 0.75, green: 0.5, blue: 1.0)) {
            VStack(alignment: .leading, spacing: 10) {
                header
                
                if !hourlyScores.isEmpty {
                    TemperatureTrendChart(hourlyScores: hourlyScores)
                        .padding(.horizontal, 8)
                        .frame(height: 120)
                }
                
                hourlyPillsList
            }
            .padding(.bottom, 10)
        }
    }
    
    private var header: some View {
        Label(L10n.text("home_hourly_label"), systemImage: "clock.fill")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.5))
            .padding(.horizontal, 12)
    }
    
    private var hourlyPillsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // LazyHStack for smooth scrolling with many hours
            LazyHStack(spacing: 6) {
                ForEach(hourlyScores) { item in
                    HourlyPill(item: item)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - Hourly Pill

struct HourlyPill: View {
    let item: HourlyScoreItem
    
    private var color: Color {
        AppTheme.color(for: WeatherScore(rawValue: item.score))
    }
    
    var body: some View {
        VStack(spacing: 4) {
            hourLabel
            scoreBadge
            weatherIcon
            temperature
            
            if item.precipitationChance > 0.05 {
                precipitationIndicator
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.12), lineWidth: 0.5)
        )
        // Apple HIG: 44pt minimum touch target
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(format: "%02d:00", item.hour)): \(item.temperatureText), Outdoor score \(item.score)")
    }
    
    private var hourLabel: some View {
        Text(String(format: "%02d:00", item.hour))
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.5))
    }
    
    private var scoreBadge: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 24, height: 24)
            
            Text(String(item.score))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
        }
    }
    
    private var weatherIcon: some View {
        Image(systemName: item.symbolName)
            .font(.system(size: 13))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
    }
    
    private var temperature: some View {
        Text(item.temperatureText)
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.6))
    }
    
    private var precipitationIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: "drop.fill")
                .font(.system(size: 7))
            
            Text(String(format: "%0.0f%%", item.precipitationChance * 100))
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.8))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        HourlyForecastView(hourlyScores: [
            HourlyScoreItem(date: Date(), hour: 14, score: 85, symbolName: "sun.max.fill", temperatureText: "24°", precipitationChance: 0.1),
            HourlyScoreItem(date: Date().addingTimeInterval(3600), hour: 15, score: 82, symbolName: "sun.max.fill", temperatureText: "25°", precipitationChance: 0.1),
            HourlyScoreItem(date: Date().addingTimeInterval(7200), hour: 16, score: 78, symbolName: "cloud.sun.fill", temperatureText: "23°", precipitationChance: 0.2),
            HourlyScoreItem(date: Date().addingTimeInterval(10800), hour: 17, score: 70, symbolName: "cloud.fill", temperatureText: "21°", precipitationChance: 0.3),
            HourlyScoreItem(date: Date().addingTimeInterval(14400), hour: 18, score: 65, symbolName: "cloud.fill", temperatureText: "20°", precipitationChance: 0.4),
            HourlyScoreItem(date: Date().addingTimeInterval(18000), hour: 19, score: 60, symbolName: "cloud.moon.fill", temperatureText: "19°", precipitationChance: 0.2)
        ])
        .padding()
    }
}
