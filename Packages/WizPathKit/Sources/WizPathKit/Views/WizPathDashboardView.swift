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
                    
                    // Global Glassmorphic Loading Overlay
                    if !viewModel.didLoadInitialLocation || viewModel.isCalculating {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 20) {
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
                                            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                                rotationAngle = 360
                                            }
                                        }
                                }
                                
                                Text(loadingText(viewModel: viewModel))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .transition(.opacity)
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
    private func openMapsURL(
        nativeURL: @escaping () -> String?,
        webURL: @escaping () -> String?
    ) {
        isNavigatingToMaps = true
        mapsError = nil
        navigationRotationAngle = 0
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            navigationRotationAngle = 360
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let urlStr = nativeURL(), let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
                // Auto-dismiss after app switch
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isNavigatingToMaps = false
                }
            } else if let webStr = webURL(), let webURL = URL(string: webStr) {
                UIApplication.shared.open(webURL, options: [:])
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
                    
                    // Cycling safety panel (only when in cycling mode)
                    if viewModel.travelMode == .cycling, let safety = viewModel.cyclingSafetyAnalysis {
                        CyclingSafetyPanel(safety: safety).padding(.horizontal, 16)
                    }
                    // EV recommendations panel (only for electric cars with heat)
                    if viewModel.travelMode == .car, viewModel.isElectricVehicle, !viewModel.evRecommendations.isEmpty {
                        EVRecommendationsPanel(recommendations: viewModel.evRecommendations).padding(.horizontal, 16)
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
                                    viewModel.selectedWaypointIds = Set(waypoints.map(\.id))
                                    pendingMapsAction = { [weak viewModel] in
                                        guard let vm = viewModel else { return }
                                        onMapsExport { openMapsURL(nativeURL: { vm.appleMapsURLString() }, webURL: { vm.appleMapsWebURLString() }) }
                                    }
                                    showWaypointPicker = true
                                }
                            },
                            onOpenInGoogleMaps: {
                                let waypoints = viewModel.mapsWaypoints
                                if waypoints.isEmpty {
                                    onMapsExport { openMapsURL(nativeURL: { viewModel.googleMapsURLString() }, webURL: { viewModel.googleMapsWebURLString() }) }
                                } else {
                                    viewModel.selectedWaypointIds = Set(waypoints.map(\.id))
                                    pendingMapsAction = { [weak viewModel] in
                                        guard let vm = viewModel else { return }
                                        onMapsExport { openMapsURL(nativeURL: { vm.googleMapsURLString() }, webURL: { vm.googleMapsWebURLString() }) }
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
                    Text(WizPathKitL10n.text("wizpath_powered_by_apple_maps")).font(.caption2).foregroundStyle(.tertiary).padding(.top, 4).padding(.bottom, 24)
                }
            }.safeAreaPadding(.bottom, 8)
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
        .alert(WizPathKitL10n.text("wizpath_route_error"), isPresented: .init(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.dismissError() } })) {
            Button(WizPathKitL10n.text("wizpath_retry")) {
                viewModel.dismissError()
                Task { await viewModel.refreshRoute() }
            }
            Button(WizPathKitL10n.text("wizpath_cancel")) { viewModel.dismissError() }
        } message: { Text(viewModel.errorMessage ?? "") }
        // Waypoint Picker
        .sheet(isPresented: $showWaypointPicker) {
            NavigationStack {
                WizPathWaypointPickerSheet(
                    waypoints: viewModel.mapsWaypoints,
                    selectedIds: viewModel.selectedWaypointIds ?? Set(viewModel.mapsWaypoints.map(\.id)),
                    onSelectionChanged: { ids in
                        viewModel.selectedWaypointIds = ids
                    },
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
}


