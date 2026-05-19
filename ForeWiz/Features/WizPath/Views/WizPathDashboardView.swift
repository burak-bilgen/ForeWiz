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
            .animation(AppTheme.cardSpring, value: viewModel.state)
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
        WizPathDestinationContent(
            viewModel: viewModel,
            showDestinationPicker: { showDestinationPicker = true }
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
                    OfflineBanner(retry: { Task { await viewModel.calculateRoute() } })
                        .padding(.horizontal, 16)
                }

                // Journey HUD (compact)
                if viewModel.showJourneyHUD, let route = viewModel.currentRoute {
                    JourneyHUDView(data: route.journeyHUDData)
                        .padding(.horizontal, 16)
                }

                // Route info panel
                if let route = viewModel.currentRoute {
                    WizPathRouteInfoPanel(
                        route: route,
                        destinationName: viewModel.destinationName,
                        bestDepartureTime: viewModel.bestDepartureTime,
                        departureTimeReason: viewModel.departureTimeReason,
                        showDepartureOptimizer: { showDepartureOptimizer = true },
                        onReset: { viewModel.reset() },
                        onUpdateDepartureTime: { viewModel.updateDepartureTime($0) }
                    )
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
}

// MARK: - Preview

#Preview {
    WizPathDashboardView()
}
