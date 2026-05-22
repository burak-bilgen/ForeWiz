import SwiftUI
import CoreLocation

// MARK: - Route Info Panel

public struct WizPathRouteInfoPanel: View {
    let route: WizPathRoute
    let destinationName: String
    let bestDepartureTime: Date?
    let departureTimeReason: String?
    let showDepartureOptimizer: () -> Void
    let onReset: () -> Void
    let onUpdateDepartureTime: (Date) -> Void

    public init(route: WizPathRoute, destinationName: String, bestDepartureTime: Date?, departureTimeReason: String?, showDepartureOptimizer: @escaping () -> Void, onReset: @escaping () -> Void, onUpdateDepartureTime: @escaping (Date) -> Void) {
        self.route = route; self.destinationName = destinationName; self.bestDepartureTime = bestDepartureTime; self.departureTimeReason = departureTimeReason; self.showDepartureOptimizer = showDepartureOptimizer; self.onReset = onReset; self.onUpdateDepartureTime = onUpdateDepartureTime
    }

    public var body: some View {
        LiquidGlassCard(accentColor: AppTheme.routeRiskColor(route.overallRisk), innerPadding: 16) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(destinationName.isEmpty ? WizPathKitL10n.text("wizpath_destination") : destinationName).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white).lineLimit(1)
                        HStack(spacing: 6) { Image(systemName: route.travelMode.icon).font(.system(size: 10)); Text(route.travelMode.localizedTitle).font(.system(size: 11, weight: .medium)) }.foregroundStyle(.secondary)
                    }
                    Spacer()
                    RouteRiskBadge(risk: route.overallRisk)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(WizPathKitL10n.text("wizpath_total_time")).font(.caption2).foregroundStyle(.tertiary)
                        Text(formattedDuration(route.totalDuration)).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white).monospacedDigit()
                    }
                }
                HStack(spacing: 0) {
                    RouteStatItem(icon: "arrow.triangle.swap", value: formattedDistance(route.totalDistance), label: WizPathKitL10n.text("wizpath_distance"))
                    Spacer()
                    if let temp = route.segments.first?.weather?.temperature {
                        RouteStatItem(icon: "thermometer.medium", value: "\(Int(temp))°", label: WizPathKitL10n.text("wizpath_avg_temp"))
                        Spacer()
                    }
                    RouteStatItem(icon: "exclamationmark.triangle.fill", value: "\(route.weatherChangePoints.count)", label: WizPathKitL10n.text("wizpath_weather_changes"))
                }
                    if let bestTime = bestDepartureTime, let reason = departureTimeReason, bestTime > Date() {
                    Divider().overlay(Color.white.opacity(0.06))
                    WizPathBestDepartureRow(bestTime: bestTime, reason: reason, onSet: onUpdateDepartureTime)
                }
                if !route.weatherChangePoints.isEmpty {
                    Divider().overlay(Color.white.opacity(0.06))
                    WizPathWeatherTimeline(segments: route.segments, changePoints: route.weatherChangePoints)
                }
                Divider().overlay(Color.white.opacity(0.06))
                HStack(spacing: 10) {
                    LiquidGlassButton(WizPathKitL10n.text("wizpath_departure_optimizer"), icon: "clock.badge.checkmark.fill", style: .secondary, haptic: .light) { showDepartureOptimizer(); HapticEngine.shared.medium() }
                    LiquidGlassButton(WizPathKitL10n.text("wizpath_new_route"), icon: "arrow.clockwise", style: .primary, haptic: .light) { onReset() }
                }
            }
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600; let m = (Int(duration) % 3600) / 60
        if h > 0 { return "\(h) \(WizPathKitL10n.text("wizpath_hours")) \(m) \(WizPathKitL10n.text("wizpath_minutes"))" }
        return "\(m) \(WizPathKitL10n.text("wizpath_minutes"))"
    }

    private func formattedDistance(_ dist: CLLocationDistance) -> String {
        let km = dist / 1000
        return km >= 10 ? "\(Int(km)) \(WizPathKitL10n.text("unit_km"))" : String(format: "%.1f \(WizPathKitL10n.text("unit_km"))", km)
    }
}

// MARK: - Route Risk Badge

public struct RouteRiskBadge: View {
    let risk: RouteRisk
    public init(risk: RouteRisk) { self.risk = risk }
    public var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Color(hex: risk.color)).frame(width: 8, height: 8)
            Text(risk.localizedTitle).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: risk.color))
        }.padding(.horizontal, 10).padding(.vertical, 5).background(Color(hex: risk.color).opacity(0.12)).clipShape(Capsule())
    }
}

// MARK: - Best Departure Row

public struct WizPathBestDepartureRow: View {
    let bestTime: Date; let reason: String; let onSet: (Date) -> Void
    public init(bestTime: Date, reason: String, onSet: @escaping (Date) -> Void) { self.bestTime = bestTime; self.reason = reason; self.onSet = onSet }
    public var body: some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(Color.success.opacity(0.12)).frame(width: 32, height: 32); Image(systemName: "clock.badge.checkmark.fill").font(.system(size: 14)).foregroundStyle(Color.success) }
            VStack(alignment: .leading, spacing: 1) {
                Text(WizPathKitL10n.text("wizpath_best_time_to_leave")).font(.system(size: 10, weight: .semibold)).foregroundStyle(.tertiary)
                Text(bestTime.formatted(date: .omitted, time: .shortened)).font(.system(size: 15, weight: .bold)).foregroundStyle(Color.success)
                Text(reason).font(.system(size: 10)).foregroundStyle(.tertiary).lineLimit(1)
            }
            Spacer()
            Button(WizPathKitL10n.text("wizpath_set_departure_time")) { onSet(bestTime) }
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.success).padding(.horizontal, 10).padding(.vertical, 5).background(Color.success.opacity(0.1)).clipShape(Capsule())
        }
    }
}

// MARK: - Route Stat Item

public struct RouteStatItem: View {
    let icon: String; let value: String; let label: String
    public init(icon: String, value: String, label: String) { self.icon = icon; self.value = value; self.label = label }
    public var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(Color.liquidAccent).symbolRenderingMode(.hierarchical)
            Text(value).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.tertiary)
        }.frame(maxWidth: .infinity)
    }
}
