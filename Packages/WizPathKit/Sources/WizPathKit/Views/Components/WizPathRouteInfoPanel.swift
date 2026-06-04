import SwiftUI
import CoreLocation

// MARK: - Route Info Config

public struct RouteInfoConfig {
    public let route: WizPathRoute
    public let destinationName: String
    public let bestDepartureTime: Date?
    public let departureTimeReason: String?
    public let trafficCongestion: TrafficCongestionLevel?
    public let hasTollRoads: Bool
    public let avoidTollRoads: Bool
    public let candidateCount: Int

    public init(route: WizPathRoute, destinationName: String, bestDepartureTime: Date? = nil,
                departureTimeReason: String? = nil, trafficCongestion: TrafficCongestionLevel? = nil,
                hasTollRoads: Bool = false, avoidTollRoads: Bool = false, candidateCount: Int = 0) {
        self.route = route
        self.destinationName = destinationName
        self.bestDepartureTime = bestDepartureTime
        self.departureTimeReason = departureTimeReason
        self.trafficCongestion = trafficCongestion
        self.hasTollRoads = hasTollRoads
        self.avoidTollRoads = avoidTollRoads
        self.candidateCount = candidateCount
    }
}

// MARK: - Route Info Panel

public struct WizPathRouteInfoPanel: View {
    let config: RouteInfoConfig
    let showDepartureOptimizer: () -> Void
    let onReset: () -> Void
    let onUpdateDepartureTime: (Date) -> Void
    let onOpenInAppleMaps: () -> Void
    let onOpenInGoogleMaps: () -> Void
    let onShowRouteComparison: () -> Void

    public init(config: RouteInfoConfig,
                showDepartureOptimizer: @escaping () -> Void,
                onReset: @escaping () -> Void,
                onUpdateDepartureTime: @escaping (Date) -> Void,
                onOpenInAppleMaps: @escaping () -> Void = {},
                onOpenInGoogleMaps: @escaping () -> Void = {},
                onShowRouteComparison: @escaping () -> Void = {}) {
        self.config = config
        self.showDepartureOptimizer = showDepartureOptimizer
        self.onReset = onReset
        self.onUpdateDepartureTime = onUpdateDepartureTime
        self.onOpenInAppleMaps = onOpenInAppleMaps
        self.onOpenInGoogleMaps = onOpenInGoogleMaps
        self.onShowRouteComparison = onShowRouteComparison
    }

    public var body: some View {
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 16) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(config.destinationName.isEmpty ? WizPathKitL10n.text("wizpath_destination") : config.destinationName).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white).lineLimit(1)
                        HStack(spacing: 6) { Image(systemName: config.route.travelMode.icon).font(.system(size: 10)); Text(config.route.travelMode.localizedTitle).font(.system(size: 11, weight: .medium)) }.foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(WizPathKitL10n.text("wizpath_total_time")).font(.caption2).foregroundStyle(.tertiary)
                        Text(formattedDuration(config.route.totalDuration)).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white).monospacedDigit()
                    }
                }
                HStack(spacing: 0) {
                    RouteStatItem(icon: "arrow.triangle.swap", value: WizPathKitFormatters.formattedDistance(config.route.totalDistance), label: WizPathKitL10n.text("wizpath_distance"))
                    Spacer()
                    if let temp = config.route.segments.first?.weather?.temperature {
                        RouteStatItem(icon: "thermometer.medium", value: WizPathKitL10n.formatted("wizpath_temperature_format", Int(temp)), label: WizPathKitL10n.text("wizpath_avg_temp"))
                        Spacer()
                    }
                    RouteStatItem(icon: "exclamationmark.triangle.fill", value: "\(config.route.weatherChangePoints.count)", label: WizPathKitL10n.text("wizpath_weather_changes"))
                }
                    if let bestTime = config.bestDepartureTime, let reason = config.departureTimeReason, bestTime > Date() {
                    Divider().overlay(Color.white.opacity(0.06))
                    WizPathBestDepartureRow(bestTime: bestTime, reason: reason, onSet: onUpdateDepartureTime)
                }
                // Traffic & Toll Info Row
                if let congestion = config.trafficCongestion, congestion != .unknown {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: congestion.colorHex))
                        Text(congestion.localizedTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: congestion.colorHex))
                        Spacer()
                        if config.hasTollRoads {
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
                        if config.avoidTollRoads && config.hasTollRoads {
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
                if config.candidateCount > 1 {
                    Button {
                        HapticEngine.shared.light()
                        onShowRouteComparison()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 11))
                            Text(WizPathKitL10n.formatted("wizpath_route_alternatives", config.candidateCount))
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

                if !config.route.weatherChangePoints.isEmpty {
                    Divider().overlay(Color.white.opacity(0.06))
                    WizPathWeatherTimeline(segments: config.route.segments, changePoints: config.route.weatherChangePoints)
                }
                Divider().overlay(Color.white.opacity(0.06))
                
                // Navigate Route section
                VStack(spacing: 10) {
                    Text(WizPathKitL10n.text("wizpath_navigate_route"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        WizPathRouteMapButton(
                            title: WizPathKitL10n.text("wizpath_apple_maps"),
                            subtitle: WizPathKitL10n.text("wizpath_open_in_maps"),
                            icon: "map.fill",
                            gradientColors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.0, green: 0.33, blue: 0.85)]
                        ) { onOpenInAppleMaps() }
                        
                        WizPathRouteMapButton(
                            title: WizPathKitL10n.text("wizpath_google_maps"),
                            subtitle: WizPathKitL10n.text("wizpath_open_in_maps"),
                            icon: "mappin.circle.fill",
                            gradientColors: [Color(red: 0.15, green: 0.68, blue: 0.38), Color(red: 0.08, green: 0.52, blue: 0.28)]
                        ) { onOpenInGoogleMaps() }
                    }
                    
                    // Legal attribution
                    Text(WizPathKitL10n.text("wizpath_maps_attribution"))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.25))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
                
                Divider().overlay(Color.white.opacity(0.06))
                HStack(spacing: 12) {
                    LiquidGlassButton(WizPathKitL10n.text("wizpath_departure_optimizer"), icon: "clock.badge.checkmark.fill", style: .secondary, haptic: .light, isFullWidth: true) { showDepartureOptimizer(); HapticEngine.shared.medium() }
                    LiquidGlassButton(WizPathKitL10n.text("wizpath_new_route"), icon: "arrow.clockwise", style: .primary, haptic: .light, isFullWidth: true) { onReset() }
                }
                HStack(spacing: 12) {
                    ShareLink(item: shareText) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 12))
                            Text(WizPathKitL10n.text("wizpath_share_route"))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color.liquidAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.liquidAccent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var shareText: String {
        let eta = formattedDuration(config.route.totalDuration)
        let dist = WizPathKitFormatters.formattedDistance(config.route.totalDistance)
        let dep = config.route.departureTime.formatted(date: .omitted, time: .shortened)
        let arr = config.route.segments.last?.etaDisplay ?? "-"
        return WizPathKitL10n.formatted("wizpath_share_format", config.destinationName, dep, arr, eta, dist)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600; let m = (Int(duration) % 3600) / 60
        if h > 0 { return "\(h) \(WizPathKitL10n.text("wizpath_hours")) \(m) \(WizPathKitL10n.text("wizpath_minutes"))" }
        return "\(m) \(WizPathKitL10n.text("wizpath_minutes"))"
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

// MARK: - Premium Glass Map Button

struct WizPathRouteMapButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            WizPathKitHaptics.provider.medium()
            action()
        } label: {
            VStack(spacing: 8) {
                // Brand icon with gradient circle
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: gradientColors.first?.opacity(0.4) ?? .clear, radius: 8, x: 0, y: 4)

                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 110)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    
                    // Subtle tint overlay matching the service color
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(gradientColors.first?.opacity(0.06) ?? .clear)
                    
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.12), gradientColors.first?.opacity(0.2) ?? .clear, .clear],
                                startPoint: .top,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .shadow(color: gradientColors.first?.opacity(0.12) ?? .clear, radius: isPressed ? 4 : 10, x: 0, y: isPressed ? 2 : 6)
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
