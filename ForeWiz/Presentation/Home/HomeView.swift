import SwiftUI
import SwiftData
import WizPathKit

// MARK: - Liquid Glass Home View
/// Premium weather assistant home screen with Liquid Glass aesthetic.
/// Features animated orb backgrounds, glass cards, micro-interactions, and accessibility.
struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String

    let onRecommendationLoaded: (DailyRecommendation) -> Void
    let onLocationsChanged: ([SavedLocation], String) -> Void
    let wizPathService: WizPathService?

    @State private var showLocationPicker = false
    @AppStorage("hasSeenAppSplash") private var hasSeenSplash = false
    @State private var showSplash = true
    @State private var contentReady = false
    @State private var toolbarAppeared = false
    @State private var showWizPathSheet = false
    @State private var showFeedbackSheet = false
    @State private var showFeedbackDashboard = false
    @State private var feedbackStore = FeedbackDashboardStore.shared
    @State private var showMapsExportSheet = false
    @State private var mapsExportStatus: MapsExportStatus = .idle
    @State private var mapsExportProceed: (() -> Void)?
    
    private enum MapsExportStatus {
        case idle
        case loadingAd
        case timedOut
        case error(String)
        case ready
        
        var isActive: Bool {
            switch self {
            case .idle: return false
            default: return true
            }
        }
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

                // Weather particle background - günün hava durumuna göre animasyon
                EnhancedWeatherParticles(kind: splashKind, progress: viewModel.particleIntensity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                content

                if showSplash && !hasSeenSplash {
                    EnhancedWeatherSplashOverlay(
                        kind: splashKind,
                        onDismiss: { showSplash = false },
                        onFadeOut: {
                            withAnimation(AppTheme.cardSpring) {
                                contentReady = true
                            }
                        }
                    )
                    .ignoresSafeArea()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                    .onAppear { hasSeenSplash = true }
                } else {
                    Color.clear.onAppear {
                        contentReady = true
                    }
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
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackSheetView()
            }
            .sheet(isPresented: $showFeedbackDashboard) {
                FeedbackDashboardView()
            }
            .fullScreenCover(isPresented: $showWizPathSheet) {
                ZStack {
                    if let wizService = wizPathService {
                        WizPathDashboardView(
                            wizPathService: wizService,
                            onMapsExport: { proceedToMaps in
                                handleMapsExport(proceedToMaps: proceedToMaps)
                            },
                            onFeedback: { showFeedbackSheet = true }
                        )
                    }
                }
                .sheet(isPresented: $showMapsExportSheet) {
                    mapsExportSheetContent
                }
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .loaded(let state) = newState { onRecommendationLoaded(state.recommendation) }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HomeBetaBadge()
                .opacity(toolbarAppeared ? 1 : 0)
                .offset(y: toolbarAppeared ? 0 : -4)
                .animation(AppTheme.defaultEaseOut.delay(AppTheme.defaultDelay + 0.05), value: toolbarAppeared)
        }

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
            HStack(spacing: 2) {
                Menu {
                    Button {
                        HapticEngine.shared.light()
                        showFeedbackSheet = true
                    } label: {
                        Label(L10n.text("feedback_sheet_title"), systemImage: "paperplane.fill")
                    }

                    Button {
                        HapticEngine.shared.light()
                        showFeedbackDashboard = true
                    } label: {
                        Label(L10n.text("feedback_dashboard_title"), systemImage: "list.bullet.rectangle")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        if feedbackStore.unreadCount > 0 {
                            Text(String(feedbackStore.unreadCount))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#FFD60A"))
                                .clipShape(Capsule())
                        }
                    }
                }
                .accessibilityLabel(L10n.text("feedback_sheet_title"))

                ToolbarLanguageButton()
            }
            .opacity(toolbarAppeared ? 1 : 0)
            .offset(y: toolbarAppeared ? 0 : -4)
            .animation(AppTheme.defaultEaseOut.delay(AppTheme.defaultDelay + 0.10), value: toolbarAppeared)
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
                onWizPathTap: { showWizPathSheet = true }
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

    // MARK: - Maps Export (Rewarded Ad Flow)

    private func handleMapsExport(proceedToMaps: @escaping () -> Void) {
        mapsExportProceed = proceedToMaps
        mapsExportStatus = .loadingAd
        showMapsExportSheet = true
        HapticEngine.shared.light()

        Task { @MainActor in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                mapsExportStatus = .error(L10n.text("error_unknown"))
                return
            }

            let adUnitID = AdManager.AdUnit.rewarded.currentID

            // Timeout: if ad doesn't load in 10 seconds, proceed directly
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    mapsExportStatus = .timedOut
                    HapticEngine.shared.warning()
                    proceedToMaps()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showMapsExportSheet = false
                        mapsExportProceed = nil
                    }
                }
            }

            // Track whether the reward flow completed (ad shown or failed)
            var rewardFlowCompleted = false
            
            AdMobRewardedIntegration.shared.loadRewardedAd(adUnitID: adUnitID) { success in
                timeoutTask.cancel()
                Task { @MainActor in
                    if success {
                        mapsExportStatus = .ready
                        let presented = AdMobRewardedIntegration.shared.showRewardedAd(
                            from: rootVC,
                            reward: .default,
                            onRewardGranted: { _ in
                                rewardFlowCompleted = true
                                Task { @MainActor in
                                    AdManager.shared.recordReward(.rewarded, amount: 1.0)
                                    showMapsExportSheet = false
                                    HapticEngine.shared.success()
                                    proceedToMaps()
                                    mapsExportProceed = nil
                                }
                            },
                            onRewardFailed: {
                                rewardFlowCompleted = true
                                Task { @MainActor in
                                    showMapsExportSheet = false
                                    HapticEngine.shared.warning()
                                    proceedToMaps()
                                    mapsExportProceed = nil
                                }
                            }
                        )
                        
                        // If ad couldn't be presented, proceed directly
                        if !presented {
                            showMapsExportSheet = false
                            HapticEngine.shared.warning()
                            proceedToMaps()
                            mapsExportProceed = nil
                        } else {
                            // Presentation safety timeout: if ad doesn't play within 5s, auto-proceed
                            Task {
                                try? await Task.sleep(nanoseconds: 5_000_000_000)
                                guard !Task.isCancelled else { return }
                                await MainActor.run {
                                    // Only proceed if the reward flow hasn't completed yet
                                    guard !rewardFlowCompleted, mapsExportProceed != nil else { return }
                                    showMapsExportSheet = false
                                    HapticEngine.shared.warning()
                                    proceedToMaps()
                                    mapsExportProceed = nil
                                }
                            }
                        }
                    } else {
                        mapsExportStatus = .error(L10n.text("maps_export_error"))
                        HapticEngine.shared.warning()
                        // Auto-dismiss and proceed after showing error
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        showMapsExportSheet = false
                        proceedToMaps()
                        mapsExportProceed = nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var mapsExportSheetContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "map.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.linearGradient(
                        colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9F0A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Text(L10n.text("maps_export_title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(L10n.text("maps_export_description"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Status indicator
                HStack(spacing: 10) {
                    switch mapsExportStatus {
                    case .idle, .loadingAd:
                        ProgressView()
                            .tint(Color(hex: "#FFD60A"))
                            .scaleEffect(0.9)
                        Text(L10n.text("maps_export_loading"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))

                    case .timedOut:
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "#FF9F0A"))
                        Text(L10n.text("maps_export_timeout"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#FF9F0A"))

                    case .error(let message):
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "#FF453A"))
                        Text(message)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#FF453A"))

                    case .ready:
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "#30D158"))
                        Text(L10n.text("maps_export_complete"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#30D158"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.05))
                )

                // Skip button (only during loading)
                if case .loadingAd = mapsExportStatus {
                    Button {
                        HapticEngine.shared.light()
                        showMapsExportSheet = false
                        mapsExportProceed?()
                        mapsExportProceed = nil
                    } label: {
                        Text(L10n.text("maps_export_skip"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .underline()
                    }
                }
            }
        }
        .presentationDetents([.height(320)])
        .presentationBackground(.ultraThinMaterial)
    }
}

// MARK: - Beta Badge

struct HomeBetaBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(Color(hex: "#FFD60A"))
                .frame(width: 4, height: 4)
            Text(L10n.text("beta_badge_label"))
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .fixedSize()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    guard let container = try? ModelContainer(for: UserPreferencesModel.self, WeatherSnapshotModel.self) else {
        return Text(L10n.text("preview_unavailable"))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
    }
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
    return HomeView(
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
                dateProvider: dateProvider
            ),
            preferencesRepository: preferencesRepo,
            homeViewStateFactory: factory
        ),
        savedLocations: .constant([]),
        selectedLocationID: .constant("current"),
        onRecommendationLoaded: { _ in },
        onLocationsChanged: { _, _ in },
        wizPathService: nil
    )
}
