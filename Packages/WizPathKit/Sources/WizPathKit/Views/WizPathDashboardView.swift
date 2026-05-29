import SwiftUI
import CoreLocation
import UIKit

// MARK: - WizPath Dashboard View

public struct WizPathDashboardView: View {
    @State private var viewModel: WizPathViewModel?
    @Environment(\.dismiss) private var dismiss
    @State private var showDestinationPicker = false
    @State private var showDepartureOptimizer = false
    @State private var showWeatherDetail = false
    @State private var showChargingStationDetail = false
    @State private var showWaypointPicker = false
    @State private var pendingMapsAction: (() -> Void)?
    @Namespace private var travelModeNamespace
    private let wizPathService: WizPathService
    private let departureOptimizerService: DepartureOptimizerService?
    
    @State private var rotationAngle: Double = 0
    @State private var isNavigatingToMaps = false
    @State private var navigationRotationAngle: Double = 0
    @State private var mapsError: String?
    @State private var contentAppeared = false
    @State private var loadingDotOffset: CGFloat = 0


    /// Closure that handles maps export (e.g. showing a rewarded ad first).
    /// Default implementation proceeds directly to the maps action.
    /// The closure receives the actual maps-open action and must call it when ready.
    private let onMapsExport: (@escaping () -> Void) -> Void
    /// Closure that presents the feedback sheet.
    private let onFeedback: () -> Void

    public init(wizPathService: WizPathService, departureOptimizerService: DepartureOptimizerService? = nil,
                onMapsExport: @escaping (@escaping () -> Void) -> Void = { $0() },
                onFeedback: @escaping () -> Void = {}) {
        self.wizPathService = wizPathService
        self.departureOptimizerService = departureOptimizerService
        self.onMapsExport = onMapsExport
        self.onFeedback = onFeedback
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()
                if let viewModel {
                    contentView(viewModel: viewModel)
                        .opacity(contentAppeared ? 1 : 0)
                        .scaleEffect(contentAppeared ? 1 : 0.92, anchor: .bottom)
                        .onAppear {
                            withAnimation(AppTheme.sheetSpring.delay(0.05)) {
                                contentAppeared = true
                            }
                        }
                    
                    // Global Glassmorphic Loading Overlay
                    if !viewModel.didLoadInitialLocation || viewModel.isCalculating {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 24) {
                                // ── Spinner ──
                                ZStack {
                                    Circle()
                                        .stroke(Color.liquidAccent.opacity(0.15), lineWidth: 6)
                                        .frame(width: 64, height: 64)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.3)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.liquidAccent, Color.liquidAccentSoft],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                        )
                                        .frame(width: 64, height: 64)
                                        .rotationEffect(.degrees(rotationAngle))
                                        .onAppear {
                                            startSpinner()
                                        }
                                }
                                
                                // ── Stage Text ──
                                Text(loadingText(viewModel: viewModel))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .contentTransition(.numericText())
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.didLoadInitialLocation)
                            }
                        }
                        .transition(.opacity)
                        .zIndex(999)
                    }
                    
                    // Maps Navigation Loading Overlay
                    if isNavigatingToMaps {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 24) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9F0A")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                ZStack {
                                    Circle()
                                        .stroke(Color(hex: "#FFD60A").opacity(0.15), lineWidth: 6)
                                        .frame(width: 64, height: 64)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.3)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9F0A")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                        )
                                        .frame(width: 64, height: 64)
                                        .rotationEffect(.degrees(navigationRotationAngle))
                                        .onAppear {
                                            startNavigationSpinner()
                                        }
                                }
                                
                                if let error = mapsError {
                                    VStack(spacing: 8) {
                                        Text(error)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color(hex: "#FF453A"))
                                            .multilineTextAlignment(.center)
                                        
                                        Button(WizPathKitL10n.text("wizpath_ok")) {
                                            isNavigatingToMaps = false
                                        }
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#FFD60A"))
                                    }
                                } else {
                                    Text(WizPathKitL10n.text("wizpath_navigating_to_maps"))
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                        .zIndex(998)
                    }
                } else {
                    ProgressView().task {
                        guard viewModel == nil else { return }
                        viewModel = WizPathViewModel(
                            wizPathService: wizPathService,
                            departureOptimizerService: departureOptimizerService
                        )
                    }
                }
            }
            .navigationTitle(WizPathKitL10n.text("wizpath_route_planner"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // WizPath logo placeholder
                    Image(systemName: "map.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.liquidAccent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 2) {
                        Button {
                            HapticEngine.shared.light()
                            onFeedback()
                        } label: {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Button { HapticEngine.shared.light(); dismiss() } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundStyle(.secondary).symbolRenderingMode(.hierarchical)
                        }.accessibilityLabel(WizPathKitL10n.text("wizpath_close"))
                    }
                }
            }
            .animation(AppTheme.cardSpring, value: viewModel?.state)
            .animation(.easeInOut(duration: 0.25), value: viewModel?.didLoadInitialLocation)
            .animation(.easeInOut(duration: 0.25), value: viewModel?.isCalculating)
        }
    }

    private func loadingText(viewModel: WizPathViewModel) -> String {
        if !viewModel.didLoadInitialLocation {
            return WizPathKitL10n.text("wizpath_loading_location")
        } else {
            return WizPathKitL10n.text("wizpath_planning_route")
        }
    }

    /// Opens the given maps URL with a loading overlay.
    /// Falls back to the web URL if the native app is not installed.
    /// Dismisses the overlay immediately if neither URL can be opened,
    /// or after a short delay to allow the app switch animation to play.
    /// - Parameter preferWeb: When true, tries the web URL first (native `maps://`
    ///   doesn't support waypoints via multiple `daddr` params).
    private func openMapsURL(
        nativeURL: @escaping () -> String?,
        webURL: @escaping () -> String?,
        preferWeb: Bool = false
    ) {
        isNavigatingToMaps = true
        mapsError = nil
        // Spinner animation is handled by startNavigationSpinner() in the overlay's .onAppear.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let primary = preferWeb ? webURL : nativeURL
            let secondary = preferWeb ? nativeURL : webURL
            if let urlStr = primary(), let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
                // Auto-dismiss after app switch
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isNavigatingToMaps = false
                }
            } else if let secStr = secondary(), let secURL = URL(string: secStr) {
                UIApplication.shared.open(secURL, options: [:])
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isNavigatingToMaps = false
                }
            } else {
                // No maps app available — show error, let user dismiss
                mapsError = WizPathKitL10n.text("wizpath_maps_unavailable")
            }
        }
    }

    @ViewBuilder
    private func contentView(viewModel: WizPathViewModel) -> some View {
        if viewModel.mapsNavigationRoute != nil { activeRouteContent(viewModel: viewModel) }
        else { destinationSelectionContent(viewModel: viewModel) }
    }

    private func destinationSelectionContent(viewModel: WizPathViewModel) -> some View {
        WizPathDestinationContent(viewModel: viewModel, showDestinationPicker: { showDestinationPicker = true })
            .sheet(isPresented: $showDestinationPicker) {
                DestinationPickerView(recentDestinations: viewModel.recentDestinations, onSelect: { coordinate, name in viewModel.setDestination(coordinate: coordinate, name: name) }, onSelectRecent: { recent in viewModel.selectRecentDestination(recent) })
            }
            .alert(WizPathKitL10n.text("wizpath_route_error"), isPresented: .init(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.dismissError() } })) {
                Button(WizPathKitL10n.text("wizpath_ok")) { viewModel.dismissError() }
            } message: { Text(viewModel.errorMessage ?? "") }
    }

    private func activeRouteContent(viewModel: WizPathViewModel) -> some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // ── Expandable map ──
                    let mapHeight: CGFloat = viewModel.mapExpanded
                        ? geometry.size.height * 0.55
                        : min(220, geometry.size.height * 0.30)
                    
                    ZStack(alignment: .top) {
                        WizPathMapView(viewModel: viewModel)
                            .frame(height: mapHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                            .overlay(alignment: .bottomTrailing) {
                                // Expand/collapse hint label
                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.mapExpanded ? "chevron.down" : "chevron.up")
                                        .font(.system(size: 8, weight: .bold))
                                    Text(viewModel.mapExpanded
                                         ? WizPathKitL10n.text("wizpath_map_collapse")
                                         : WizPathKitL10n.text("wizpath_map_expand"))
                                        .font(.system(size: 8, weight: .semibold))
                                }
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .environment(\.colorScheme, .dark)
                                .padding(10)
                                .onTapGesture {
                                    withAnimation(AppTheme.cardSpring) {
                                        viewModel.mapExpanded.toggle()
                                        HapticEngine.shared.light()
                                    }
                                }
                            }
                        
                        if viewModel.isLoadingMapDetails {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.white)
                                Text(WizPathKitL10n.text("wizpath_loading_smart_stops"))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.5))
                            .padding(.top, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if viewModel.state.isOffline { OfflineBanner(retry: { Task { await viewModel.calculateRoute() } }).padding(.horizontal, 16) }
                    
                    // Travel mode picker on active route screen - Premium Sliding Capsule
                    LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 4) {
                        HStack(spacing: 4) {
                            ForEach(TravelMode.allCases) { mode in
                                Button {
                                    guard viewModel.travelMode != mode else { return }
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.76)) {
                                        viewModel.switchTravelMode(to: mode)
                                    }
                                    HapticEngine.shared.selectionChanged()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: mode.icon)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(mode.localizedTitle)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(viewModel.travelMode == mode ? .white : .white.opacity(0.55))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background {
                                        if viewModel.travelMode == mode {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.liquidAccent.opacity(0.35), Color.liquidAccentSoft.opacity(0.18)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                                                )
                                                .matchedGeometryEffect(id: "activeTab", in: travelModeNamespace)
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                    }
                    .padding(.horizontal, 16)

                    if viewModel.travelMode == .car {
                        VStack(spacing: 6) {
                            electricVehicleToggle(viewModel: viewModel)
                            tollRoadToggle(viewModel: viewModel)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Route Comparison
                    if viewModel.showRouteComparison && viewModel.routeCandidates.count > 1 {
                        RouteComparisonCard(
                            candidates: viewModel.routeCandidates,
                            selectedIndex: viewModel.selectedRouteIndex,
                            onSelect: { viewModel.selectRouteCandidate(at: $0) },
                            onClose: { withAnimation(AppTheme.cardSpring) { viewModel.showRouteComparison = false } }
                        )
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if viewModel.showJourneyHUD, let route = viewModel.mapsNavigationRoute {
                        JourneyHUDView(data: route.journeyHUDData).padding(.horizontal, 16)
                    }

                    // Elevation profile card
                    if let profile = viewModel.elevationProfile {
                        ElevationCardView(profile: profile, hasTollRoads: viewModel.hasTollRoads)
                            .padding(.horizontal, 16)
                    }

                    // Cycling safety panel (only when in cycling mode)
                    if viewModel.travelMode == .cycling, let safety = viewModel.cyclingSafetyAnalysis {
                        CyclingSafetyPanel(safety: safety).padding(.horizontal, 16)
                    }
                    // EV charging stations panel — shows real POI data along the route
                    if viewModel.travelMode == .car, viewModel.isElectricVehicle {
                        EvRangePlannerPanel(
                            chargingStations: viewModel.chargingStations.filter { $0.category == .evCharger }
                        )
                        .padding(.horizontal, 16)
                    }
                    if let route = viewModel.mapsNavigationRoute {
                        WizPathRouteInfoPanel(
                            route: route,
                            destinationName: viewModel.destinationName,
                            bestDepartureTime: viewModel.bestDepartureTime,
                            departureTimeReason: viewModel.departureTimeReason,
                            showDepartureOptimizer: { showDepartureOptimizer = true },
                            onReset: { viewModel.reset() },
                            onUpdateDepartureTime: { viewModel.updateDepartureTime($0) },
                            onOpenInAppleMaps: {
                                let waypoints = viewModel.mapsWaypoints
                                if waypoints.isEmpty {
                                    onMapsExport { openMapsURL(nativeURL: { viewModel.appleMapsURLString() }, webURL: { viewModel.appleMapsWebURLString() }) }
                                } else {
                                    viewModel.selectedWaypointIds = []
                                    pendingMapsAction = { [weak viewModel] in
                                        guard let vm = viewModel else { return }
                                        // Web URL'yi önce dene — native maps:// waypoint'leri desteklemiyor
                                        onMapsExport { openMapsURL(
                                            nativeURL: { vm.appleMapsURLString() },
                                            webURL: { vm.appleMapsWebURLString() },
                                            preferWeb: true
                                        )}
                                    }
                                    showWaypointPicker = true
                                }
                            },
                            onOpenInGoogleMaps: {
                                let waypoints = viewModel.mapsWaypoints
                                if waypoints.isEmpty {
                                    onMapsExport { openMapsURL(nativeURL: { viewModel.googleMapsURLString() }, webURL: { viewModel.googleMapsWebURLString() }) }
                                } else {
                                    viewModel.selectedWaypointIds = []
                                    pendingMapsAction = { [weak viewModel] in
                                        guard let vm = viewModel else { return }
                                        // Web URL'yi önce dene — native maps:// waypoint'leri desteklemiyor
                                        onMapsExport { openMapsURL(
                                            nativeURL: { vm.googleMapsURLString() },
                                            webURL: { vm.googleMapsWebURLString() },
                                            preferWeb: true
                                        )}
                                    }
                                    showWaypointPicker = true
                                }
                            },
                            trafficCongestion: viewModel.currentTrafficCongestion,
                            hasTollRoads: viewModel.hasTollRoads,
                            avoidTollRoads: viewModel.avoidTollRoads,
                            candidateCount: viewModel.routeCandidates.count,
                            onShowRouteComparison: { withAnimation(AppTheme.cardSpring) { viewModel.showRouteComparison.toggle() } }
                        )
                        .padding(.horizontal, 16)
                    }
                    // ── Inline Error Card (non-disruptive, shown when cached route exists) ──
                    if let errorMsg = viewModel.errorMessage, viewModel.mapsNavigationRoute != nil {
                        RouteErrorCard(
                            message: errorMsg,
                            isDismissable: true,
                            onRetry: {
                                viewModel.dismissError()
                                Task { await viewModel.refreshRoute() }
                            },
                            onDismiss: { viewModel.dismissError() }
                        )
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    Text(WizPathKitL10n.text("wizpath_powered_by_apple_maps")).font(.caption2).foregroundStyle(.tertiary).padding(.top, 4).padding(.bottom, 24)
                }
            }
            .refreshable {
                if viewModel.mapsNavigationRoute != nil {
                    await viewModel.refreshRoute()
                }
            }
            .safeAreaPadding(.bottom, 8)
        }
        .sheet(isPresented: $showDepartureOptimizer) {
            if let route = viewModel.mapsNavigationRoute {
                WizPathDepartureOptimizerSheet(route: route, onSelectTime: { date in viewModel.updateDepartureTime(date); showDepartureOptimizer = false })
            }
        }
        .onChange(of: viewModel.showWeatherDetail) { _, newValue in
            showWeatherDetail = newValue
        }
        .sheet(isPresented: $showWeatherDetail) {
            Group {
                if let segment = viewModel.selectedWeatherSegment, let weather = segment.weather {
                    WeatherDetailSheet(segment: segment, weather: weather)
                }
            }
            .onDisappear {
                viewModel.showWeatherDetail = false
                viewModel.selectedWeatherSegment = nil
            }
        }
        .onChange(of: viewModel.showChargingStationDetail) { _, newValue in
            showChargingStationDetail = newValue
        }
        .sheet(isPresented: $showChargingStationDetail) {
            Group {
                if let station = viewModel.selectedChargingStation {
                    ChargingStationDetailSheet(station: station)
                }
            }
            .onDisappear {
                viewModel.showChargingStationDetail = false
                viewModel.selectedChargingStation = nil
            }
        }
                // Waypoint Picker
        .sheet(isPresented: $showWaypointPicker) {
            NavigationStack {
                WizPathWaypointPickerSheet(
                    waypoints: viewModel.mapsWaypoints,
                    onNavigate: { ids in
                        viewModel.selectedWaypointIds = ids
                        pendingMapsAction?()
                        pendingMapsAction = nil
                    },
                    onNavigateWithoutStops: {
                        viewModel.selectedWaypointIds = []
                        pendingMapsAction?()
                        pendingMapsAction = nil
                    }
                )
            }
        }
    }

    private func tollRoadToggle(viewModel: WizPathViewModel) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(viewModel.avoidTollRoads ? Color(hex: "#FF9500") : .secondary)
            
            Text(WizPathKitL10n.text("wizpath_avoid_tolls_title"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle(isOn: Binding(get: { viewModel.avoidTollRoads }, set: { _ in viewModel.toggleAvoidTollRoads() })) {}
                .tint(Color(hex: "#FF9500"))
                .scaleEffect(0.85)
                .labelsHidden()
                .accessibilityLabel(WizPathKitL10n.text("wizpath_avoid_tolls_title"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .accessibilityAddTraits(viewModel.avoidTollRoads ? .isSelected : [])
    }

    private func electricVehicleToggle(viewModel: WizPathViewModel) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.car.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(viewModel.isElectricVehicle ? Color(hex: POICategory.evCharger.color) : .secondary)
            
            Text(WizPathKitL10n.text("wizpath_ev_mode_title"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle(isOn: Binding(get: { viewModel.isElectricVehicle }, set: { enabled in viewModel.setElectricVehicleEnabled(enabled) })) {}
                .tint(Color(hex: POICategory.evCharger.color))
                .scaleEffect(0.85)
                .labelsHidden()
                .accessibilityLabel(WizPathKitL10n.text("wizpath_ev_mode_title"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .accessibilityAddTraits(viewModel.isElectricVehicle ? .isSelected : [])
    }

    // MARK: - Spinner Helpers

    /// Starts the route-loading spinner animation.
    /// Resets the angle to 0 first so the animation always runs even when the overlay
    /// reappears after initial location load (where rotationAngle would be stuck at 360).
    private func startSpinner() {
        rotationAngle = 0
        DispatchQueue.main.async {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }

    /// Starts the maps-navigation spinner animation (same fix).
    private func startNavigationSpinner() {
        navigationRotationAngle = 0
        DispatchQueue.main.async {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                navigationRotationAngle = 360
            }
        }
    }
}

// MARK: - Loading Stage Dot

private struct LoadingStageDot: View {
    let isActive: Bool
    let offset: CGFloat

    var body: some View {
        Circle()
            .fill(isActive ? Color.liquidAccent : Color.white.opacity(0.25))
            .frame(width: 8, height: 8)
            .offset(y: isActive ? offset : 0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: offset)
            .scaleEffect(isActive ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.4), value: isActive)
    }
}

// MARK: - Route Error Card

private struct RouteErrorCard: View {
    let message: String
    let isDismissable: Bool
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "#FF453A").opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(hex: "#FF453A"))
            }

            // Message
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineLimit(4)

            // Buttons
            HStack(spacing: 12) {
                if isDismissable {
                    Button(action: onDismiss) {
                        Text(WizPathKitL10n.text("wizpath_cancel"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                }

                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .bold))
                        Text(WizPathKitL10n.text("wizpath_retry"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FF453A"), Color(hex: "#FF375F")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "#FF453A").opacity(0.2), lineWidth: 1)
                )
        )
    }
}


