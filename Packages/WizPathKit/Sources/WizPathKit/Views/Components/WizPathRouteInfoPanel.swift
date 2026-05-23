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
    let onOpenInAppleMaps: () -> Void
    let onOpenInGoogleMaps: () -> Void
    let trafficCongestion: TrafficCongestionLevel?
    let hasTollRoads: Bool
    let avoidTollRoads: Bool
    let candidateCount: Int
    let onShowRouteComparison: () -> Void

    public init(route: WizPathRoute, destinationName: String, bestDepartureTime: Date?, departureTimeReason: String?,
                showDepartureOptimizer: @escaping () -> Void, onReset: @escaping () -> Void,
                onUpdateDepartureTime: @escaping (Date) -> Void,
                onOpenInAppleMaps: @escaping () -> Void = {}, onOpenInGoogleMaps: @escaping () -> Void = {},
                trafficCongestion: TrafficCongestionLevel? = nil, hasTollRoads: Bool = false,
                avoidTollRoads: Bool = false, candidateCount: Int = 0,
                onShowRouteComparison: @escaping () -> Void = {}) {
        self.route = route; self.destinationName = destinationName; self.bestDepartureTime = bestDepartureTime
        self.departureTimeReason = departureTimeReason; self.showDepartureOptimizer = showDepartureOptimizer
        self.onReset = onReset; self.onUpdateDepartureTime = onUpdateDepartureTime
        self.onOpenInAppleMaps = onOpenInAppleMaps; self.onOpenInGoogleMaps = onOpenInGoogleMaps
        self.trafficCongestion = trafficCongestion; self.hasTollRoads = hasTollRoads
        self.avoidTollRoads = avoidTollRoads; self.candidateCount = candidateCount
        self.onShowRouteComparison = onShowRouteComparison
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
                // Traffic & Toll Info Row
                if let congestion = trafficCongestion, congestion != .unknown {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: congestion.colorHex))
                        Text(congestion.localizedTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: congestion.colorHex))
                        Spacer()
                        if hasTollRoads {
                            HStack(spacing: 3) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 9))
                                Text(WizPathKitL10n.text("route_label_toll"))
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: "#FF9500"))
                        } else {
                            HStack(spacing: 3) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 9))
                                Text(WizPathKitL10n.text("route_label_free"))
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(Color.success)
                        }
                        if avoidTollRoads && hasTollRoads {
                            HStack(spacing: 3) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 9))
                                Text(WizPathKitL10n.text("route_label_avoiding"))
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: "#FF9500"))
                        }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Route comparison entry
                if candidateCount > 1 {
                    Button {
                        HapticEngine.shared.light()
                        onShowRouteComparison()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 11))
                            Text(WizPathKitL10n.formatted("wizpath_route_alternatives", candidateCount))
                                .font(.system(size: 11, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(Color.liquidAccent)
                        .padding(8)
                        .background(Color.liquidAccent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                if !route.weatherChangePoints.isEmpty {
                    Divider().overlay(Color.white.opacity(0.06))
                    WizPathWeatherTimeline(segments: route.segments, changePoints: route.weatherChangePoints)
                }
                Divider().overlay(Color.white.opacity(0.06))
                
                // Navigate Route section
                VStack(spacing: 8) {
                    Text(WizPathKitL10n.text("wizpath_navigate_route"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 10) {
                        PremiumGlassMapButtonSmall(
                            title: WizPathKitL10n.text("wizpath_apple_maps"),
                            icon: "map.fill",
                            gradientColors: [.blue, Color(red: 0.1, green: 0.6, blue: 0.95)]
                        ) { onOpenInAppleMaps() }
                        
                        PremiumGlassMapButtonSmall(
                            title: WizPathKitL10n.text("wizpath_google_maps"),
                            icon: "arrow.triangle.turn.up.right.diamond.fill",
                            gradientColors: [Color(red: 0.15, green: 0.65, blue: 0.35), Color(red: 0.25, green: 0.75, blue: 0.55)]
                        ) { onOpenInGoogleMaps() }
                    }
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
        let unit = WizPathKitL10n.text("unit_km")
        return km >= 10 ? "\(Int(km)) \(unit)" : String(format: "%.1f \(unit)", km)
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

// MARK: - Premium Glass Map Button (Compact)

struct PremiumGlassMapButtonSmall: View {
    let title: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            WizPathKitHaptics.provider.medium()
            action()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: gradientColors.first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 2)

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.15), .white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    WizPathKitHaptics.provider.selectionChanged()
                }
                .onEnded { _ in isPressed = false }
        )
        .animation(AppTheme.pressSpring, value: isPressed)
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
