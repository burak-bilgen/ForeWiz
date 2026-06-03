import SwiftUI
import WizPathKit

// MARK: - Weekly Forecast Section

struct WeeklyForecastSection: View {
    let dailyForecasts: [DailyForecastItem]

    var body: some View {
        LiquidGlassCard(accentColor: AppTheme.sky) {
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.text("home_forecast_label"), systemImage: "calendar")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)

                ForEach(dailyForecasts.prefix(7)) { forecast in
                    ForecastRow(forecast: forecast)
                    if forecast.id != dailyForecasts.prefix(7).last?.id {
                        Divider()
                            .background(.white.opacity(0.04))
                    }
                }
            }
        }
    }
}

// MARK: - Forecast Row

struct ForecastRow: View {
    let forecast: DailyForecastItem

    private var scoreColor: Color {
        switch forecast.outdoorScore {
        case 70...100: AppTheme.success
        case 40..<70: AppTheme.warning
        default: AppTheme.danger
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Day name — today highlighted
            Text(forecast.dayName)
                .font(.system(size: 14, weight: forecast.isToday ? .bold : .semibold, design: .rounded))
                .foregroundStyle(forecast.isToday ? .white : .white.opacity(0.6))
                .frame(minWidth: 72, maxWidth: 88, alignment: .leading)
                .lineLimit(1)

            Image(systemName: forecast.conditionSymbol)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 20)

            // Temperature range
            HStack(spacing: 4) {
                Text("\(Int(round(forecast.highTemp)))\(L10n.text("unit_degree"))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(Int(round(forecast.lowTemp)))\(L10n.text("unit_degree"))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineLimit(1)
            }
            .frame(width: 60)

            Spacer()

            if forecast.precipitationChance > 0.05 {
                HStack(spacing: 3) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                    Text("\(Int(forecast.precipitationChance * 100))\(L10n.text("unit_percent"))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(AppTheme.sky)
                .frame(width: 44)
            }

            // Score capsule progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.06))
                    Capsule()
                        .fill(scoreColor.opacity(0.7))
                        .frame(width: geo.size.width * CGFloat(forecast.outdoorScore) / 100.0)
                }
            }
            .frame(width: 36, height: 6)
        }
        .padding(.vertical, forecast.isToday ? 2 : 0)
    }
}
