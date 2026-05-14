import SwiftUI
@preconcurrency import MapKit
import CoreLocation

// MARK: - WizPath Dashboard View
struct WizPathDashboardView: View {
    @StateObject private var viewModel = WizPathViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDestinationPicker = false
    @State private var showTimePicker = false
    @State private var showDepartureOptimizer = false
    @State private var dashboardLoadTrigger = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Section
                    heroHeader

                    // Route Map
                    WizPathMapView(viewModel: viewModel)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Trip Planner
                    plannerCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Journey HUD
                    if viewModel.showJourneyHUD, let route = viewModel.currentRoute {
                        JourneyHUDView(data: route.journeyHUDData)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Departure Optimizer Button
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
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(L10n.text("wizpath_route_planner"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticEngine.shared.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.tertiary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibleButton(label: L10n.text("wizpath_close"))
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
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.state)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.showJourneyHUD)
        }
    }

    // MARK: - Hero Header
    private var heroHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)
                    .symbolEffect(.bounce, value: dashboardLoadTrigger)

                Text(L10n.text("wizpath_smart_route_planner"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if viewModel.isCalculating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Text(L10n.text("wizpath_weather_aware_routing"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                dashboardLoadTrigger = true
            }
        }
    }

    // MARK: - Planner Card
    private var plannerCard: some View {
        GlassCard(innerPadding: 16) {
            VStack(spacing: 14) {
                // Destination Field
                destinationField

                // Travel Mode + Departure Time
                HStack(spacing: 10) {
                    travelModePicker
                    departureTimeButton
                }

                // Calculate Button
                calculateButton
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
                    .fill(.blue.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("wizpath_destination"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(viewModel.destinationName.isEmpty ? L10n.text("wizpath_select_destination_placeholder") : viewModel.destinationName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.destinationName.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Destinations Quick Access
    private var recentDestinationsRow: some View {
        Group {
            if !viewModel.recentDestinations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.recentDestinations.prefix(5), id: \.self) { recent in
                            Button {
                                viewModel.selectRecentDestination(recent)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 10))
                                    Text(recent.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
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

    // MARK: - Departure Time
    private var departureTimeButton: some View {
        Button {
            showTimePicker = true
            HapticEngine.shared.selectionChanged()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                Text(formattedTime(viewModel.departureTime))
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showTimePicker) {
            DatePicker(
                L10n.text("wizpath_departure_time"),
                selection: $viewModel.departureTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(width: 200, height: 200)
            .padding()
            .presentationCompactAdaptation(.popover)
            .onChange(of: viewModel.departureTime) { _, _ in
                viewModel.refreshRoute()
            }
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
                Text(viewModel.isCalculating ? L10n.text("wizpath_calculating") : L10n.text("wizpath_calculate_route"))
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(viewModel.canCalculate ? Color.blue : Color.gray.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!viewModel.canCalculate)
        .buttonStyle(.plain)
    }

    // MARK: - Departure Optimizer Button
    private var departureOptimizerButton: some View {
        Button {
            showDepartureOptimizer = true
            HapticEngine.shared.medium()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.multicolor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("wizpath_departure_optimizer"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
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
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
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
        GlassCard(innerPadding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                // Header with risk indicator
                HStack(spacing: 12) {
                    // Risk badge
                    riskBadge(route.overallRisk)

                    Spacer()

                    // Duration
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.text("wizpath_total_time"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(formattedDuration(route.totalDuration))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }
                }

                // Stats Row
                HStack(spacing: 0) {
                    statItem(icon: route.travelMode.icon, value: route.travelMode.localizedTitle, label: L10n.text("wizpath_mode"))
                    Spacer()
                    statItem(icon: "arrow.triangle.swap", value: formattedDistance(route.totalDistance), label: L10n.text("wizpath_distance"))
                    Spacer()
                    if let temp = route.segments.first?.weather?.temperature {
                        statItem(icon: "thermometer.medium", value: "\\(Int(temp))°", label: L10n.text("wizpath_avg_temp"))
                    }
                }

                // Weather Along Route
                if !route.weatherChangePoints.isEmpty {
                    Divider()
                        .padding(.vertical, 2)

                    weatherTimeline(route)
                }

                // Action buttons
                Divider()
                    .padding(.vertical, 2)

                HStack(spacing: 10) {
                    Button {
                        viewModel.reset()
                    } label: {
                        Label(L10n.text("wizpath_new_route"), systemImage: "plus.circle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.refreshRoute()
                    } label: {
                        Label(L10n.text("wizpath_refresh"), systemImage: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Risk Badge
    private func riskBadge(_ risk: RouteRisk) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: risk.color))
                .frame(width: 10, height: 10)
                .glow(color: Color(hex: risk.color), radius: 4)

            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.text("wizpath_route_risk"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(risk.localizedTitle)
                    .font(.system(size: 14, weight: .bold))
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
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 56, height: 72)

                    VStack(spacing: 4) {
                        Image(systemName: weather.iconName)
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: weather.severity.colorHex))
                            .shadow(color: Color(hex: weather.severity.colorHex).opacity(0.3), radius: 3)

                        Text("\\(Int(weather.temperature))°")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)

                        Text(segment.etaShortDisplay)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 56, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: weather.severity.colorHex).opacity(0.25), lineWidth: 1)
                )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 56, height: 72)
                    .overlay(ProgressView().scaleEffect(0.6))
            }
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

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
        return km >= 10 ? "\(Int(km)) km" : String(format: "%.1f km", km)
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Glow Effect
extension View {
    func glow(color: Color, radius: CGFloat) -> some View {
        self.background(
            Circle()
                .fill(color)
                .blur(radius: radius)
                .scaleEffect(1.5)
        )
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
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.multicolor)

                Text(L10n.text("wizpath_optimize_departure"))
                    .font(.system(size: 20, weight: .bold))

                Text(L10n.text("wizpath_optimize_departure_desc"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            // Time Picker
            HStack(spacing: 16) {
                // Hour picker
                VStack {
                    Text(L10n.text("wizpath_hour"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Picker("", selection: $selectedHour) {
                        ForEach(0..<24) { hour in
                            Text(String(format: "%02d", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                }

                Text(":")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.secondary)
                    .offset(y: -10)

                // Minute picker
                VStack {
                    Text(L10n.text("wizpath_minute"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Picker("", selection: $selectedMinute) {
                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                }
            }

            // Quick select buttons
            VStack(spacing: 8) {
                Text(L10n.text("wizpath_quick_times"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 8) {
                    ForEach([6, 8, 10, 12, 14, 16, 18, 20], id: \.self) { hour in
                        Button {
                            selectedHour = hour
                            selectedMinute = 0
                        } label: {
                            Text(String(format: "%02d:00", hour))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(selectedHour == hour ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedHour == hour ? Color.blue : Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            // Apply button
            Button {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                components.hour = selectedHour
                components.minute = selectedMinute
                if let date = calendar.date(from: components) {
                    onSelectTime(date)
                }
            } label: {
                Text(L10n.text("wizpath_set_departure_time"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.text("wizpath_departure_optimizer"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text("wizpath_done")) { dismiss() }
            }
        }
    }
}

// MARK: - WizPath Journey HUD Data
extension WizPathRoute {
    var journeyHUDData: JourneyHUDData {
        let hazards = [EnvironmentalHazard]() // Real hazard detection would go here
        let safeStops = [SmartStop]() // Real POI data would go here

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
