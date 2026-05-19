import SwiftUI
import SwiftData

// MARK: - Liquid Glass Home View
/// Premium weather assistant home screen with Liquid Glass aesthetic.
/// Features animated orb backgrounds, glass cards, micro-interactions, and accessibility.
struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String

    let onRecommendationLoaded: (DailyRecommendation) -> Void
    let onLocationsChanged: ([SavedLocation], String) -> Void

    @State private var showLocationPicker = false
    @State private var showSplash = true
    @State private var contentReady = false
    @State private var toolbarAppeared = false
    @State private var showWizPathSheet = false

    private var wizPathRouteStatus: RouteStatus {
        WizPathHUDStatus.shared.currentStatus
    }

    private var currentSymbol: String {
        if case .loaded(let state) = viewModel.state { return state.currentWeather.symbolName }
        return "cloud.fill"
    }

    private var splashKind: EnhancedWeatherSplashKind {
        EnhancedWeatherSplashKind.from(symbolName: currentSymbol)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidOrbBackground(palette: orbPalette)
                    .ignoresSafeArea()
                    .animation(AppTheme.slowEaseOut, value: currentSymbol)

                content

                if showSplash {
                    EnhancedWeatherSplashOverlay(
                        kind: splashKind,
                        onDismiss: { showSplash = false },
                        onFadeOut: {
                            withAnimation(AppTheme.springSmooth) {
                                contentReady = true
                            }
                        }
                    )
                    .ignoresSafeArea()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { toolbarContent }
            .task { viewModel.onAppear() }
            .onAppear { animateToolbar() }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    savedLocations: $savedLocations,
                    selectedLocationID: $selectedLocationID,
                    onSelect: { location in Task { await viewModel.changeLocation(to: location) } },
                    onLocationsChanged: { locations in onLocationsChanged(locations, selectedLocationID) }
                )
            }
            .fullScreenCover(isPresented: $showWizPathSheet) {
                WizPathDashboardView()
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .loaded(let state) = newState { onRecommendationLoaded(state.recommendation) }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            ToolbarLocationButton(
                locationName: viewModel.selectedLocationName,
                action: { showLocationPicker = true }
            )
            .opacity(toolbarAppeared ? 1 : 0)
            .offset(y: toolbarAppeared ? 0 : -4)
            .animation(AppTheme.defaultEaseOut.delay(AppTheme.defaultDelay), value: toolbarAppeared)
        }

        ToolbarItem(placement: .topBarTrailing) {
            ToolbarLanguageButton()
                .opacity(toolbarAppeared ? 1 : 0)
                .offset(y: toolbarAppeared ? 0 : -4)
                .animation(AppTheme.defaultEaseOut.delay(AppTheme.defaultDelay + 0.05), value: toolbarAppeared)
        }
    }

    private func animateToolbar() {
        withAnimation(AppTheme.slowEaseOut.delay(AppTheme.defaultDelay + 0.12)) {
            toolbarAppeared = true
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            HomeLoadingView()
                .transition(.opacity)
        case .failed(let message):
            HomeErrorView(message: message, retry: { Task { await viewModel.refresh() } })
                .transition(.opacity)
        case .loaded(let state):
            HomeLoadedContent(
                state: state,
                contentReady: contentReady,
                refresh: { await viewModel.refresh() },
                showWizPathSheet: $showWizPathSheet,
                wizPathRouteStatus: wizPathRouteStatus
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.97)),
                removal: .opacity
            ))
        }
    }

    // MARK: - Orb Palette

    private var orbPalette: LiquidOrbBackground.OrbPalette {
        switch currentSymbol {
        case _ where currentSymbol.contains("storm") || currentSymbol.contains("thunder"):
            return .stormy
        case _ where currentSymbol.contains("snow") || currentSymbol.contains("sleet"):
            return .snowy
        case _ where currentSymbol.contains("rain") || currentSymbol.contains("drizzle"):
            return .default
        case _ where currentSymbol.contains("fog") || currentSymbol.contains("mist"):
            return .default
        case _ where currentSymbol.contains("sun") || currentSymbol.contains("clear"):
            return .clearSky
        case _ where currentSymbol.contains("moon"):
            return .night
        default:
            return .default
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: UserPreferencesModel.self, WeatherSnapshotModel.self)
    let modelContext = container.mainContext
    let preferencesRepo = SwiftDataPreferencesRepository(modelContext: modelContext)
    let weatherCacheRepo = SwiftDataWeatherCacheRepository(modelContext: modelContext)
    let dateProvider = SystemDateProvider()
    let activityEngine = DefaultActivityWindowScoringEngine()
    let outfitEngine = DefaultOutfitDecisionEngine()
    let weatherEngine = DefaultWeatherDecisionEngine(
        activityWindowScoringEngine: activityEngine,
        outfitDecisionEngine: outfitEngine
    )
    let factory = HomeViewStateFactory(
        dateProvider: dateProvider,
        activityWindowScoringEngine: activityEngine
    )
    HomeView(
        viewModel: HomeViewModel(
            loadHomeRecommendationUseCase: DefaultLoadHomeRecommendationUseCase(
                locationRepository: MockLocationRepository(),
                weatherRepository: MockWeatherRepository(),
                weatherCacheRepository: weatherCacheRepo,
                preferencesRepository: preferencesRepo,
                weatherDecisionEngine: weatherEngine,
                dateProvider: dateProvider
            ),
            scheduleSmartNotificationsUseCase: DefaultScheduleSmartNotificationsUseCase(
                notificationRepository: UserNotificationRepository(),
                notificationPlanningEngine: DefaultNotificationPlanningEngine(),
                dateProvider: dateProvider,
                severeWeatherAlertService: SevereWeatherAlertService.shared
            ),
            preferencesRepository: preferencesRepo,
            homeViewStateFactory: factory
        ),
        savedLocations: .constant([]),
        selectedLocationID: .constant("current"),
        onRecommendationLoaded: { _ in },
        onLocationsChanged: { _, _ in }
    )
}
