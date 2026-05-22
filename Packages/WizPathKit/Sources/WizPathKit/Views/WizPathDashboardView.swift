import SwiftUI
import CoreLocation

// MARK: - WizPath Dashboard View

public struct WizPathDashboardView: View {
    @State private var viewModel: WizPathViewModel?
    @Environment(\.dismiss) private var dismiss
    @State private var showDestinationPicker = false
    @State private var showDepartureOptimizer = false
    private let wizPathService: WizPathService

    public init(wizPathService: WizPathService) {
        self.wizPathService = wizPathService
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()
                if let viewModel { contentView(viewModel: viewModel) }
                else { ProgressView().task {
                    guard viewModel == nil else { return }
                    viewModel = WizPathViewModel(wizPathService: wizPathService)
                }}
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
                    WizPathMapView(viewModel: viewModel)
                        .frame(height: min(260, geometry.size.height * 0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
                        .padding(.horizontal, 16).padding(.top, 8)
                    if viewModel.state.isOffline { OfflineBanner(retry: { Task { await viewModel.calculateRoute() } }).padding(.horizontal, 16) }
                    if viewModel.showJourneyHUD, let route = viewModel.currentRoute {
                        JourneyHUDView(data: route.journeyHUDData).padding(.horizontal, 16)
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
        .alert(WizPathKitL10n.text("wizpath_route_error"), isPresented: .init(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.dismissError() } })) {
            Button(WizPathKitL10n.text("wizpath_ok")) { viewModel.dismissError() }
        } message: { Text(viewModel.errorMessage ?? "") }
    }
}
