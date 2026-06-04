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
    private let onRouteEnded: ((WizPathRoute, String, TravelMode) -> Void)?

    public init(wizPathService: WizPathService, departureOptimizerService: DepartureOptimizerService? = nil,
                onMapsExport: @escaping (@escaping () -> Void) -> Void = { $0() },
                onFeedback: @escaping () -> Void = {},
                onRouteEnded: ((WizPathRoute, String, TravelMode) -> Void)? = nil) {
        self.wizPathService = wizPathService
        self.departureOptimizerService = departureOptimizerService
        self.onMapsExport = onMapsExport
        self.onFeedback = onFeedback
        self.onRouteEnded = onRouteEnded
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
                        let vm = WizPathViewModel(
                            wizPathService: wizPathService,
                            departureOptimizerService: departureOptimizerService
                        )
                        vm.onRouteEnded = onRouteEnded
                        viewModel = vm
                    }
                }
            }
            .navigationTitle(WizPathKitL10n.text("wizpath_route_planner"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { HapticEngine.shared.light(); dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundStyle(.secondary).symbolRenderingMode(.hierarchical)
                    }.accessibilityLabel(WizPathKitL10n.text("wizpath_close"))
                }
            }
            .animation(AppTheme.cardSpring, value: viewModel?.state)
            .animation(.easeInOut(duration: 0.25), value: viewModel?.didLoadInitialLocation)
            .animation(.easeInOut(duration: 0.25), value: viewModel?.isCalculating)
            .onDisappear {
                if let viewModel, let route = viewModel.lastCalculatedRoute, !viewModel.hasEndedRoute {
                    viewModel.hasEndedRoute = true
                    onRouteEnded?(route, viewModel.destinationName, viewModel.travelMode)
                }
            }
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
        ZStack(alignment: .top) {
            // ── Full-screen map ──
            WizPathMapView(viewModel: viewModel)
                .ignoresSafeArea()

            // ── Smart Stops loading indicator (top center) ──
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
                .environment(\.colorScheme, .dark)
                .padding(.top, 100)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // ── Bottom sheet drawer (non-dismissable) ──
        .sheet(isPresented: .constant(true)) {
            routeDrawerContent(viewModel: viewModel)
                .presentationDetents([.fraction(0.38), .fraction(0.85)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
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

    // MARK: - Route Drawer Content

    @ViewBuilder
    private func routeDrawerContent(viewModel: WizPathViewModel) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if viewModel.state.isOffline {
                    OfflineBanner(retry: { Task { await viewModel.calculateRoute() } })
                        .padding(.horizontal, 16)
                }

                // Travel mode picker — Premium Sliding Capsule
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
                                        .contentTransition(.opacity)
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
                    tollRoadToggle(viewModel: viewModel)
                        .padding(.horizontal, 16)
                    
                    // Vehicle type picker — only visible in car mode
                    vehicleTypePicker(viewModel: viewModel)
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
                    JourneyHUDView(data: route.journeyHUDData(smartStops: viewModel.smartStops))
                        .padding(.horizontal, 16)
                }

                // Cycling safety panel
                if viewModel.travelMode == .cycling, let safety = viewModel.cyclingSafetyAnalysis {
                    CyclingSafetyPanel(safety: safety)
                        .padding(.horizontal, 16)
                }

                // EV Charging stations panel
                // EV şarj istasyonları — sadece elektrikli/hibrit araçlar için
                if viewModel.travelMode == .car, viewModel.vehicleType == .electric || viewModel.vehicleType == .hybrid {
                    EvChargerStopsView(
                        chargingStations: viewModel.evChargers,
                        isLoading: viewModel.isLoadingEVChargers,
                        errorMessage: viewModel.evChargerError
                    ) {
                        if let route = viewModel.mapsNavigationRoute {
                            viewModel.refreshEVChargers(for: route)
                        }
                    }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let route = viewModel.mapsNavigationRoute {
                    WizPathRouteInfoPanel(
                        config: RouteInfoConfig(
                            route: route,
                            destinationName: viewModel.destinationName,
                            bestDepartureTime: viewModel.bestDepartureTime,
                            departureTimeReason: viewModel.departureTimeReason,
                            trafficCongestion: viewModel.currentTrafficCongestion,
                            hasTollRoads: viewModel.hasTollRoads,
                            avoidTollRoads: viewModel.avoidTollRoads,
                            candidateCount: viewModel.routeCandidates.count
                        ),
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
                                    onMapsExport { openMapsURL(
                                        nativeURL: { vm.googleMapsURLString() },
                                        webURL: { vm.googleMapsWebURLString() },
                                        preferWeb: true
                                    )}
                                }
                                showWaypointPicker = true
                            }
                        },
                        onShowRouteComparison: { withAnimation(AppTheme.cardSpring) { viewModel.showRouteComparison.toggle() } }
                    )
                    .padding(.horizontal, 16)
                }

                // Inline error card
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

                Text(WizPathKitL10n.text("wizpath_powered_by_apple_maps"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
                    .padding(.bottom, 32)
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Vehicle Type Picker

    private func vehicleTypePicker(viewModel: WizPathViewModel) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(VehicleType.allCases) { type in
                    Button {
                        guard viewModel.vehicleType != type else { return }
                        viewModel.vehicleType = type
                        HapticEngine.shared.selectionChanged()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 11, weight: .semibold))
                            Text(type.localizedTitle)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .contentTransition(.opacity)
                        }
                        .foregroundStyle(viewModel.vehicleType == type ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if viewModel.vehicleType == type {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(hex: type.accentColor).opacity(0.25))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
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


