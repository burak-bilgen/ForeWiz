import SwiftUI

struct DailyForecastItem: Identifiable, Equatable {
    let id = UUID()
    let dayName: String
    let date: Date
    let highTemp: Double
    let lowTemp: Double
    let conditionSymbol: String
    let outdoorScore: Int
    let outdoorDecision: OutdoorDecision
    let isToday: Bool
}

struct WeeklyForecastCard: View {
    let dailyForecasts: [DailyForecastItem]
    let isPremium: Bool

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack {
                    Label(isPremium ? String(localized: "forecast_7day") : String(localized: "forecast_3day"), systemImage: "calendar")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.ink)

                    if !isPremium {
                        Spacer()
                        NavigationLink(destination: Text(String(localized: "forecast_premium_required"))) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.sunshine)
                        }
                        .buttonStyle(.plain)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.medium) {
                        ForEach(displayedForecasts) { day in
                            DailyForecastCell(item: day)
                        }

                        if !isPremium && dailyForecasts.count > 3 {
                            PremiumForecastLockCell()
                        }
                    }
                    .padding(.horizontal, AppSpacing.xSmall)
                }
            }
        }
    }

    private var displayedForecasts: [DailyForecastItem] {
        if isPremium {
            return dailyForecasts
        }
        return Array(dailyForecasts.prefix(3))
    }
}

private struct PremiumForecastLockCell: View {
    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.sunshine.opacity(0.6))

            Text(String(localized: "forecast_7_days"))
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.sunshine)

            Text(String(localized: "forecast_premium"))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(width: 68)
        .padding(.vertical, AppSpacing.small)
        .padding(.horizontal, AppSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
                .fill(AppTheme.sunshine.opacity(0.08))
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
                .stroke(AppTheme.sunshine.opacity(0.25), lineWidth: 1.5)
        }
    }
}

private struct DailyForecastCell: View {
    let item: DailyForecastItem

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Text(item.dayName)
                .font(item.isToday ? AppTypography.caption.weight(.bold) : AppTypography.caption)
                .foregroundStyle(item.isToday ? AppTheme.accent : AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Image(systemName: item.conditionSymbol)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.accent)
                .frame(height: 28)

            VStack(spacing: AppSpacing.xSmall) {
                Circle()
                    .fill(AppTheme.color(for: item.outdoorDecision))
                    .frame(width: 8, height: 8)

                Text("\(item.outdoorScore)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            VStack(spacing: 1) {
                Text(item.highTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(item.lowTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(width: 68)
        .padding(.vertical, AppSpacing.small)
        .padding(.horizontal, AppSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
                .fill(AppTheme.surface.opacity(0.55))
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
                .stroke(item.isToday ? AppTheme.accent.opacity(0.35) : Color.clear, lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.dayName), \(String(localized: "weekly_score_accessor")) \(item.outdoorScore), \(String(localized: "weekly_high_accessor")) \(Int(item.highTemp)) \(String(localized: "weekly_low_accessor")) \(Int(item.lowTemp))")
    }
}
