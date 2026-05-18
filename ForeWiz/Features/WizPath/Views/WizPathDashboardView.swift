import SwiftUI
@preconcurrency import MapKit
import CoreLocation

// MARK: - WizPath Dashboard View
/// Premium route planning dashboard with Liquid Glass aesthetic.
/// Two clear states: destination selection | active route.
struct WizPathDashboardView: View {
    @State private var viewModel = WizPathViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDestinationPicker = false
    @State private var showDepartureOptimizer = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                content
            }
            .navigationTitle(L10n.text("wizpath_route_planner"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticEngine.shared.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel(L10n.text("wizpath_close"))
                }
            }
            .sheet(isPresented: $showDestinationPicker) {
                DestinationPickerView(
                    recentDestinations: viewModel.recentDestinations,
                    onSelect: { coordinate, name in
                        viewModel.setDestination(coordinate: coordinate, name: name)
                    },
                    onSelectRecent: { recent in
                        viewModel.selectRecentDestination(recent)
                    }
                )
            }
            .sheet(isPresented: $showDepartureOptimizer) {
                if let route = viewModel.currentRoute {
                    DepartureOptimizerView(
                        route: route,
                        onSelectTime: { date in
                            viewModel.updateDepartureTime(date)
                            showDepartureOptimizer = false
                        }
                    )
                }
            }
            .alert(L10n.text("wizpath_route_error"), isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )) {
                Button(L10n.text("wizpath_ok")) { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: viewModel.state)
            .onAppear { hasAppeared = true }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.currentRoute != nil {
            activeRouteContent
        } else {
            destinationSelectionContent
        }
    }

    // MARK: - Destination Selection State

    private var destinationSelectionContent: some View {
        VStack(spacing: 0) {
            // Map (taller when selecting)
            WizPathMapView(viewModel: viewModel)
                .frame(height: UIScreen.main.bounds.height * 0.45)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 10)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer(minLength: 16)

            // Destination prompt
            LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 20) {
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.liquidAccent.opacity(0.1))
                            .frame(width: 56, height: 56)
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.liquidAccent)
                            .symbolRenderingMode(.hierarchical)
                    }

                    VStack(spacing: 6) {
                        Text(L10n.text("wizpath_select_destination_title"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text(L10n.text("wizpath_smart_route_planner"))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Travel mode picker
                    Picker(L10n.text("wizpath_travel_mode"), selection: $viewModel.travelMode) {
                        ForEach(TravelMode.allCases) { mode in
                            Label(mode.localizedTitle, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.travelMode) { _, _ in
                        viewModel.refreshRoute()
                    }

                    // Set destination button
                    Button {
                        showDestinationPicker = true
                        HapticEngine.shared.selectionChanged()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text(L10n.text("wizpath_select_destination"))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.liquidAccent, Color.liquidAccentSoft],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .liquidAccent.opacity(0.3), radius: 12, y: 4)
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            // Recent destinations
            if !viewModel.recentDestinations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.recentDestinations.prefix(5)) { recent in
                            recentChip(recent)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 12)
            }

            Spacer(minLength: 16)

            // Offline banner
            if viewModel.state.isOffline {
                offlineBanner
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            // Attribution
            Text(L10n.text("wizpath_powered_by_apple_maps"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Recent Chip

    private func recentChip(_ recent: RecentDestination) -> some View {
        Button {
            HapticEngine.shared.medium()
            viewModel.selectRecentDestination(recent)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 10))
                Text(recent.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(0.06), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    // MARK: - Offline Banner

    private var offlineBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16))
                .foregroundStyle(Color.warning)

            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.text("wizpath_offline_title"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(L10n.text("wizpath_offline_message"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(L10n.text("wizpath_offline_retry")) {
                Task { await viewModel.calculateRoute() }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.liquidAccent)
        }
        .padding(12)
        .background(Color.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.warning.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Active Route State

    private var activeRouteContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                // Map
                WizPathMapView(viewModel: viewModel)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Offline banner
                if viewModel.state.isOffline {
                    offlineBanner
                        .padding(.horizontal, 16)
                }

                // Journey HUD (compact)
                if viewModel.showJourneyHUD, let route = viewModel.currentRoute {
                    JourneyHUDView(data: route.journeyHUDData)
                        .padding(.horizontal, 16)
                }

                // Route info panel (replaces 3 separate cards)
                if let route = viewModel.currentRoute {
                    routeInfoPanel(route)
                        .padding(.horizontal, 16)
                }

                // Attribution
                Text(L10n.text("wizpath_powered_by_apple_maps"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
            }
        }
        .safeAreaPadding(.bottom, 8)
    }

    // MARK: - Route Info Panel

    private func routeInfoPanel(_ route: WizPathRoute) -> some View {
        LiquidGlassCard(accentColor: Color.routeRiskColor(route.overallRisk), innerPadding: 16) {
            VStack(spacing: 14) {
                // Top row: Destination + Risk + Duration
                HStack(spacing: 12) {
                    // Destination name
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.destinationName.isEmpty
                             ? L10n.text("wizpath_destination")
                             : viewModel.destinationName)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Image(systemName: route.travelMode.icon)
                                .font(.system(size: 10))
                            Text(route.travelMode.localizedTitle)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Risk badge
                    riskBadge(route.overallRisk)

                    // Duration
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.text("wizpath_total_time"))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(formattedDuration(route.totalDuration))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                }

                // Stats row
                HStack(spacing: 0) {
                    statItem(icon: "arrow.triangle.swap",
                             value: formattedDistance(route.totalDistance),
                             label: L10n.text("wizpath_distance"))
                    Spacer()
                    if let temp = route.segments.first?.weather?.temperature {
                        statItem(icon: "thermometer.medium",
                                 value: "\(Int(temp))°",
                                 label: L10n.text("wizpath_avg_temp"))
                        Spacer()
                    }
                    statItem(icon: "exclamationmark.triangle.fill",
                             value: "\(route.weatherChangePoints.count)",
                             label: L10n.text("wizpath_weather_changes"))
                }

                // Best departure time suggestion
                if let bestTime = viewModel.bestDepartureTime,
                   let reason = viewModel.departureTimeReason {
                    Divider()
                        .overlay(Color.white.opacity(0.06))

                    bestDepartureRow(bestTime: bestTime, reason: reason)
                }

                // Weather timeline
                if !route.weatherChangePoints.isEmpty {
                    Divider()
                        .overlay(Color.white.opacity(0.06))

                    weatherTimeline(route)
                }

                // Action buttons
                Divider()
                    .overlay(Color.white.opacity(0.06))

                HStack(spacing: 10) {
                    // Departure optimizer
                    LiquidGlassButton(
                        L10n.text("wizpath_departure_optimizer"),
                        icon: "clock.badge.checkmark.fill",
                        style: .secondary,
                        haptic: .light
                    ) {
                        showDepartureOptimizer = true
                        HapticEngine.shared.medium()
                    }

                    // Refresh
                    LiquidGlassButton(
                        L10n.text("wizpath_new_route"),
                        icon: "arrow.clockwise",
                        style: .primary,
                        haptic: .light
                    ) {
                        viewModel.reset()
                    }
                }
            }
        }
    }

    // MARK: - Best Departure Row

    private func bestDepartureRow(bestTime: Date, reason: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.success.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.success)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.text("wizpath_best_time_to_leave"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text(bestTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.success)
                Text(reason)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            Button(L10n.text("wizpath_set_departure_time")) {
                viewModel.updateDepartureTime(bestTime)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.success)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.success.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Risk Badge

    private func riskBadge(_ risk: RouteRisk) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: risk.color))
                .frame(width: 8, height: 8)
            Text(risk.localizedTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: risk.color))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(hex: risk.color).opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Weather Timeline

    private func weatherTimeline(_ route: WizPathRoute) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("wizpath_weather_along_route"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(route.weatherChangePoints) { segment in
                        weatherSegmentCard(segment)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Weather Segment Card

    private func weatherSegmentCard(_ segment: WizPathSegment) -> some View {
        let severityColor = Color(hex: segment.weather?.severity.colorHex ?? "#ffffff")
        return VStack(spacing: 4) {
            if let weather = segment.weather {
                Image(systemName: weather.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(severityColor)
                    .shadow(color: severityColor.opacity(0.3), radius: 3)

                Text("\(Int(weather.temperature))°")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                Text(segment.etaShortDisplay)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 48, height: 60)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(severityColor.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Helpers

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 {
            return "\(h) \(L10n.text("wizpath_hours")) \(m) \(L10n.text("wizpath_minutes"))"
        }
        return "\(m) \(L10n.text("wizpath_minutes"))"
    }

    private func formattedDistance(_ dist: CLLocationDistance) -> String {
        let km = dist / 1000
        return km >= 10 ? "\(Int(km)) \(L10n.text("unit_km"))" : String(format: "%.1f \(L10n.text("unit_km"))", km)
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.liquidAccent)
                .symbolRenderingMode(.hierarchical)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Route Risk Color

extension Color {
    static func routeRiskColor(_ risk: RouteRisk) -> Color {
        switch risk {
        case .good: return Color.success
        case .caution: return Color.warning
        case .severe: return Color.danger
        }
    }
}

// MARK: - WizPathSegment + ETA Short Display

extension WizPathSegment {
    var etaShortDisplay: String {
        SharedFormatters.shortTime.string(from: estimatedArrival)
    }
}

// MARK: - Journey HUD Data (keep for previews)

extension WizPathRoute {
    var journeyHUDData: JourneyHUDData {
        let hazards = generateEnvironmentalHazards()
        return JourneyHUDData(
            totalDuration: totalDuration,
            totalDistance: totalDistance,
            hazardCount: hazards.count,
            safeStops: 0,
            safetyScore: overallRisk.safetyScore,
            activeHazards: hazards,
            nextSafeStop: nil
        )
    }

    // swiftlint:disable:next function_body_length
    private func generateEnvironmentalHazards() -> [EnvironmentalHazard] {
        var hazards: [EnvironmentalHazard] = []
        for (index, segment) in segments.enumerated() {
            guard let weather = segment.weather else { continue }
            let hazardType: HazardType?
            let details: String
            let recommendation: String

            switch weather.condition {
            case .thunderstorm:
                hazardType = .thunderstorm
                details = L10n.formatted("wizpath_hazard_thunderstorm_detail", Int(weather.windSpeed))
                recommendation = L10n.text("wizpath_hazard_thunderstorm_rec")
            case .heavyRain:
                hazardType = .heavyRain
                details = L10n.formatted("wizpath_hazard_heavyrain_detail", Int(weather.precipitationChance * 100))
                recommendation = L10n.text("wizpath_hazard_heavyrain_rec")
            case .fog:
                hazardType = .fog
                details = L10n.formatted("wizpath_hazard_fog_detail", Int(weather.visibility ?? 0))
                recommendation = L10n.text("wizpath_hazard_fog_rec")
            case .snow, .sleet:
                hazardType = .snow
                details = L10n.formatted("wizpath_hazard_snow_detail", Int(weather.temperature))
                recommendation = L10n.text("wizpath_hazard_snow_rec")
            default:
                if weather.windSpeed > 50 {
                    hazardType = .crosswind
                    details = L10n.formatted("wizpath_hazard_wind_detail", Int(weather.windSpeed))
                    recommendation = L10n.text("wizpath_hazard_wind_rec")
                } else if weather.temperature <= 0 && weather.condition == .clear {
                    hazardType = .ice
                    details = L10n.formatted("wizpath_hazard_ice_detail", Int(weather.temperature))
                    recommendation = L10n.text("wizpath_hazard_ice_rec")
                } else {
                    hazardType = nil
                    details = ""
                    recommendation = ""
                }
            }

            if let type = hazardType {
                let severity: HazardSeverity
                switch weather.severity {
                case .severe: severity = .critical
                case .caution: severity = .high
                default: severity = .moderate
                }
                hazards.append(EnvironmentalHazard(
                    id: UUID(),
                    type: type,
                    coordinate: segment.coordinate,
                    routeSegmentIndex: index,
                    severity: severity,
                    details: details,
                    recommendation: recommendation,
                    etaAtLocation: segment.estimatedArrival
                ))
            }
        }
        return hazards
    }
}

extension RouteRisk {
    var safetyScore: Int {
        switch self {
        case .good: return 85
        case .caution: return 60
        case .severe: return 30
        }
    }
}

// MARK: - Departure Optimizer View

struct DepartureOptimizerView: View {
    let route: WizPathRoute
    let onSelectTime: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHour = 8
    @State private var selectedMinute = 0

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    LiquidGlassCard(accentColor: .success, innerPadding: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.success)
                                .symbolRenderingMode(.multicolor)

                            Text(L10n.text("wizpath_optimize_departure"))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)

                            Text(L10n.text("wizpath_optimize_departure_desc"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Time Picker
                    LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 20) {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                TimePickerColumn(
                                    title: L10n.text("wizpath_hour"),
                                    range: Array(0..<24),
                                    selection: $selectedHour,
                                    format: "%02d"
                                )

                                Text(":")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .offset(y: -10)

                                TimePickerColumn(
                                    title: L10n.text("wizpath_minute"),
                                    range: Array(stride(from: 0, to: 60, by: 5)),
                                    selection: $selectedMinute,
                                    format: "%02d"
                                )
                            }

                            // Quick Select
                            VStack(spacing: 8) {
                                Text(L10n.text("wizpath_quick_times"))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                LazyVGrid(columns: [
                                    .init(.flexible()), .init(.flexible()),
                                    .init(.flexible()), .init(.flexible())
                                ], spacing: 8) {
                                    ForEach([6, 8, 10, 12, 14, 16, 18, 20], id: \.self) { hour in
                                        QuickTimeChip(
                                            hour: hour,
                                            isSelected: selectedHour == hour && selectedMinute == 0
                                        ) {
                                            selectedHour = hour
                                            selectedMinute = 0
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    // Apply Button
                    Button {
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.year, .month, .day], from: Date())
                        components.hour = selectedHour
                        components.minute = selectedMinute
                        if let date = calendar.date(from: components) {
                            onSelectTime(date)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text(L10n.text("wizpath_set_departure_time"))
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.liquidAccent, Color.liquidAccentSoft],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .liquidAccent.opacity(0.3), radius: 12, y: 4)
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
                .padding(20)
            }
        }
        .navigationTitle(L10n.text("wizpath_departure_optimizer"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text("wizpath_done")) { dismiss() }
                    .foregroundStyle(Color.liquidAccent)
            }
        }
    }
}

// MARK: - Time Picker Column

struct TimePickerColumn: View {
    let title: String
    let range: [Int]
    @Binding var selection: Int
    let format: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)

            Picker("", selection: $selection) {
                ForEach(range, id: \.self) { value in
                    Text(String(format: format, value))
                        .font(.system(size: 20, design: .rounded))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)
            .colorScheme(.dark)
        }
    }
}

// MARK: - Quick Time Chip

struct QuickTimeChip: View {
    let hour: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(L10n.formatted("time_format_full", hour))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.liquidAccent : Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Color.liquidAccent : Color.white.opacity(0.08), lineWidth: isSelected ? 1 : 0.5)
                )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    WizPathDashboardView()
}
