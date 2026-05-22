import SwiftUI
import CoreLocation

// MARK: - WizPath Dashboard View

public struct WizPathDashboardView: View {
    @State private var viewModel: WizPathViewModel?
    @Environment(\.dismiss) private var dismiss
    @State private var showDestinationPicker = false
    @State private var showDepartureOptimizer = false
    @State private var showWeatherDetail = false
    @State private var showChargingStationDetail = false
    @Namespace private var travelModeNamespace
    private let wizPathService: WizPathService
    private let departureOptimizerService: DepartureOptimizerService?
    
    @State private var rotationAngle: Double = 0

    public init(wizPathService: WizPathService, departureOptimizerService: DepartureOptimizerService? = nil) {
        self.wizPathService = wizPathService
        self.departureOptimizerService = departureOptimizerService
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button { HapticEngine.shared.light(); dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundStyle(.secondary).symbolRenderingMode(.hierarchical)
                    }.accessibilityLabel(WizPathKitL10n.text("wizpath_close"))
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

    @ViewBuilder
    private func contentView(viewModel: WizPathViewModel) -> some View {
        if viewModel.currentRoute != nil { activeRouteContent(viewModel: viewModel) }
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
                    // Map view nested inside ZStack to allow inline map details loader banner
                    ZStack(alignment: .top) {
                        WizPathMapView(viewModel: viewModel)
                            .frame(height: min(260, geometry.size.height * 0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                        
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
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: viewModel.isLoadingMapDetails)

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
                        electricVehicleToggle(viewModel: viewModel)
                            .padding(.horizontal, 16)
                    }
                    
                    if viewModel.showJourneyHUD, let route = viewModel.currentRoute {
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
                    if let route = viewModel.currentRoute {
                        WizPathRouteInfoPanel(route: route, destinationName: viewModel.destinationName, bestDepartureTime: viewModel.bestDepartureTime, departureTimeReason: viewModel.departureTimeReason, showDepartureOptimizer: { showDepartureOptimizer = true }, onReset: { viewModel.reset() }, onUpdateDepartureTime: { viewModel.updateDepartureTime($0) })
                            .padding(.horizontal, 16)
                    }
                    Text(WizPathKitL10n.text("wizpath_powered_by_apple_maps")).font(.caption2).foregroundStyle(.tertiary).padding(.top, 4).padding(.bottom, 24)
                }
            }.safeAreaPadding(.bottom, 8)
        }
        .sheet(isPresented: $showDepartureOptimizer) {
            if let route = viewModel.currentRoute {
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
            Button(WizPathKitL10n.text("wizpath_ok")) { viewModel.dismissError() }
        } message: { Text(viewModel.errorMessage ?? "") }
    }

    private func electricVehicleToggle(viewModel: WizPathViewModel) -> some View {
        Button {
            viewModel.setElectricVehicleEnabled(!viewModel.isElectricVehicle)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: POICategory.evCharger.color).opacity(viewModel.isElectricVehicle ? 0.18 : 0.08))
                        .frame(width: 34, height: 34)
                    Image(systemName: "bolt.car.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(viewModel.isElectricVehicle ? Color(hex: POICategory.evCharger.color) : .secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(WizPathKitL10n.text("wizpath_ev_mode_title"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text(WizPathKitL10n.text("wizpath_ev_mode_subtitle"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: viewModel.isElectricVehicle ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(viewModel.isElectricVehicle ? Color(hex: POICategory.evCharger.color) : .secondary)
                    .frame(width: 24, height: 24)
            }
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .accessibilityLabel(WizPathKitL10n.text("wizpath_ev_mode_title"))
        .accessibilityAddTraits(viewModel.isElectricVehicle ? .isSelected : [])
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: POICategory.evCharger.color).opacity(viewModel.isElectricVehicle ? 0.35 : 0.12), lineWidth: 1)
        )
    }
}
