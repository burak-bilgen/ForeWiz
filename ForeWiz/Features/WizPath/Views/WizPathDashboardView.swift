import SwiftUI
@preconcurrency import MapKit
import CoreLocation

// MARK: - WizPath Dashboard View
struct WizPathDashboardView: View {
    @State private var viewModel = WizPathViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDestinationPicker = false
    @State private var showDepartureOptimizer = false
    @State private var dashboardLoadTrigger = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Header
                    heroHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Offline Banner
                    if viewModel.state.isOffline {
                        offlineBanner
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }

                    // Route Map
                    WizPathMapView(viewModel: viewModel)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 10)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Empty State (no destination selected)
                    if viewModel.currentRoute == nil && viewModel.destinationCoordinate == nil {
                        emptyStateView
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                    }

                    // Planner Card
                    plannerCard
                        .padding(.horizontal, 16)
                        .padding(.top, viewModel.currentRoute == nil && viewModel.destinationCoordinate == nil ? 0 : 14)

                    // Best Departure Time Suggestion
                    if viewModel.currentRoute != nil,
                       let bestTime = viewModel.bestDepartureTime,
                       let reason = viewModel.departureTimeReason {
                        bestDepartureCard(bestTime: bestTime, reason: reason)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Journey HUD
                    if viewModel.showJourneyHUD, let route = viewModel.currentRoute {
                        JourneyHUDView(data: route.journeyHUDData)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Departure Optimizer
                    if viewModel.currentRoute != nil {
                        departureOptimizerButton
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }

                    // Route Details
                    if let route = viewModel.currentRoute {
                        routeDetailPanel(route)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }

                    // Attribution
                    if viewModel.currentRoute != nil {
                        Text(L10n.text("wizpath_powered_by_apple_maps"))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                    }
                }
            }
            .background(AppBackground())
            .navigationTitle(L10n.text("wizpath_route_planner"))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticEngine.shared.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel(L10n.text("wizpath_close"))
                    .accessibilityAddTraits(.isButton)
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
                departureOptimizerSheet
            }
            .alert(L10n.text("wizpath_route_error"), isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )) {
                Button(L10n.text("wizpath_ok")) { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert(L10n.text("wizpath_offline_title"), isPresented: .init(
                get: { viewModel.state.isOffline },
                set: { if !$0 { viewModel.dismissError() } }
            )) {
                Button(L10n.text("wizpath_offline_retry")) {
                    Task { await viewModel.calculateRoute() }
                }
                Button(L10n.text("wizpath_ok"), role: .cancel) { viewModel.dismissError() }
            } message: {
                Text(L10n.text("wizpath_offline_message"))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.state)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.showJourneyHUD)
        }
    }

    // MARK: - Hero Header
    private var heroHeader: some View {
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 16, cornerRadius: 20) {
            HStack {
                GlassIcon(systemName: "map.fill", color: .liquidAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("wizpath_smart_route_planner"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(L10n.text("wizpath_weather_aware_routing"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.isCalculating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.liquidAccent)
                }

                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.liquidAccent)
                    .opacity(dashboardLoadTrigger ? 1 : 0)
                    .scaleEffect(dashboardLoadTrigger ? 1 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4).delay(0.2)) {
                dashboardLoadTrigger = true
            }
        }
    }

    // MARK: - Offline Banner
    private var offlineBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 18))
                .foregroundStyle(Color.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.text("wizpath_offline_title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(L10n.text("wizpath_offline_message"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(L10n.text("wizpath_offline_retry")) {
                Task { await viewModel.calculateRoute() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.liquidAccent)
        }
        .padding(14)
        .background(Color.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.warning.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Color.liquidAccent.opacity(0.4))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 6) {
                Text(L10n.text("wizpath_select_destination_title"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text(L10n.text("wizpath_select_destination_subtitle"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Best Departure Card
    private func bestDepartureCard(bestTime: Date, reason: String) -> some View {
        LiquidGlassCard(accentColor: .success, innerPadding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.success.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.success)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("wizpath_best_time_to_leave"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(bestTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.success)
                    Text(reason)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button(L10n.text("wizpath_set_departure_time")) {
                    viewModel.updateDepartureTime(bestTime)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.success)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.success.opacity(0.12))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Planner Card
    private var plannerCard: some View {
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 16) {
            VStack(spacing: 14) {
                // Destination Field
                destinationField

                // Travel Mode + Calculate Button
                HStack(spacing: 10) {
                    travelModePicker
                    calculateButton
                }
            }
        }
    }

    // MARK: - Destination Field
    private var destinationField: some View {
        Button {
            showDestinationPicker = true
            HapticEngine.shared.selectionChanged()
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.liquidAccent.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.liquidAccent)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("wizpath_destination"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.destinationName.isEmpty
                        ? L10n.text("wizpath_select_destination_placeholder")
                        : viewModel.destinationName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.destinationName.isEmpty ? Color.secondary : Color.white)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color.liquidAccent.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.liquidAccent.opacity(0.12), lineWidth: 0.5)
            )
        }
        .contentShape(Rectangle())

        .buttonStyle(.plain)
    }

    // MARK: - Travel Mode Picker
    private var travelModePicker: some View {
        Picker(L10n.text("wizpath_travel_mode"), selection: $viewModel.travelMode) {
            ForEach(TravelMode.allCases) { mode in
                Label(mode.localizedTitle, systemImage: mode.icon).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.travelMode) { _, _ in
            viewModel.refreshRoute()
        }
    }

    // MARK: - Calculate Button
    private var calculateButton: some View {
        Button {
            Task { await viewModel.calculateRoute() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isCalculating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                        .symbolEffect(.bounce, value: viewModel.canCalculate)
                }
                Text(viewModel.isCalculating
                    ? L10n.text("wizpath_calculating")
                    : L10n.text("wizpath_calculate_route"))
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: viewModel.canCalculate
                        ? [Color.liquidAccent, Color.liquidAccentSoft]
                        : [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(!viewModel.canCalculate)
        .contentShape(Rectangle())

        .buttonStyle(.plain)
    }

    // MARK: - Departure Optimizer Button
    private var departureOptimizerButton: some View {
        Button {
            showDepartureOptimizer = true
            HapticEngine.shared.medium()
        } label: {
            HStack(spacing: 14) {
                GlassIcon(systemName: "clock.badge.checkmark.fill", color: .success)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("wizpath_departure_optimizer"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(L10n.text("wizpath_find_best_departure"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .contentShape(Rectangle())

        .buttonStyle(.plain)
    }

    // MARK: - Departure Optimizer Sheet
    private var departureOptimizerSheet: some View {
        NavigationStack {
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
    }

    // MARK: - Route Detail Panel
    private func routeDetailPanel(_ route: WizPathRoute) -> some View {
        LiquidGlassCard(accentColor: .routeRiskColor(route.overallRisk), innerPadding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with risk + duration
                HStack(spacing: 12) {
                    riskBadge(route.overallRisk)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.text("wizpath_total_time"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formattedDuration(route.totalDuration))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                }

                // Stats Row
                HStack(spacing: 0) {
                    statItem(
                        icon: route.travelMode.icon,
                        value: route.travelMode.localizedTitle,
                        label: L10n.text("wizpath_mode")
                    )
                    Spacer()
                    statItem(
                        icon: "arrow.triangle.swap",
                        value: formattedDistance(route.totalDistance),
                        label: L10n.text("wizpath_distance")
                    )
                    Spacer()
                    if let temp = route.segments.first?.weather?.temperature {
                        statItem(
                            icon: "thermometer.medium",
                            value: "\(Int(temp))\(L10n.text("unit_degree"))",
                            label: L10n.text("wizpath_avg_temp")
                        )
                    }
                }

                // Weather Timeline
                if !route.weatherChangePoints.isEmpty {
                    Divider()
                        .overlay(Color.white.opacity(0.06))

                    weatherTimeline(route)
                }

                // Action Buttons
                Divider()
                    .overlay(Color.white.opacity(0.06))

                HStack(spacing: 10) {
                    LiquidGlassButton(
                        L10n.text("wizpath_new_route"),
                        icon: "plus.circle",
                        style: .secondary,
                        haptic: .light
                    ) {
                        viewModel.reset()
                    }

                    LiquidGlassButton(
                        L10n.text("wizpath_refresh"),
                        icon: "arrow.clockwise",
                        style: .primary,
                        haptic: .light
                    ) {
                        viewModel.refreshRoute()
                    }
                }
            }
        }
    }

    // MARK: - Risk Badge
    private func riskBadge(_ risk: RouteRisk) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: risk.color))
                    .frame(width: 12, height: 12)

                Circle()
                    .fill(Color(hex: risk.color).opacity(0.3))
                    .frame(width: 20, height: 20)
                    .blur(radius: 4)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.text("wizpath_route_risk"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(risk.localizedTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: risk.color))
            }
        }
    }

    // MARK: - Weather Timeline
    private func weatherTimeline(_ route: WizPathRoute) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("wizpath_weather_along_route"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

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
        VStack(spacing: 5) {
            if let weather = segment.weather {
                VStack(spacing: 4) {
                    Image(systemName: weather.iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: weather.severity.colorHex))
                        .shadow(color: Color(hex: weather.severity.colorHex).opacity(0.4), radius: 4)

                    Text("\(Int(weather.temperature))\(L10n.text("unit_degree"))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)

                    Text(segment.etaShortDisplay)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 56, height: 72)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: weather.severity.colorHex).opacity(0.25), lineWidth: 1)
                )
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 56, height: 72)
                    .overlay(ProgressView().scaleEffect(0.6))
            }
        }
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
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.liquidAccent)
                .symbolRenderingMode(.hierarchical)

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
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

// MARK: - WizPath Journey HUD Data
extension WizPathRoute {
    var journeyHUDData: JourneyHUDData {
        let hazards = generateEnvironmentalHazards()
        let safeStops = [SmartStop]()
        return JourneyHUDData(
            totalDuration: totalDuration,
            totalDistance: totalDistance,
            hazardCount: hazards.count,
            safeStops: safeStops.count,
            safetyScore: overallRisk.safetyScore,
            activeHazards: hazards,
            nextSafeStop: safeStops.first
        )
    }

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

// MARK: - Preview
#Preview {
    WizPathDashboardView()
}
