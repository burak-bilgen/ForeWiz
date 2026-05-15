import OSLog
import SwiftUI

struct AppRootView: View {
    @Bindable var coordinator: AppCoordinator
    @Bindable var deepLinkHandler: DeepLinkHandler
    @State private var didStart = false

    var body: some View {
        Group {
            switch coordinator.rootFlow {
            case .onboarding:
                OnboardingView(
                    viewModel: OnboardingViewModel(
                        locationRepository: coordinator.container.locationRepository,
                        notificationRepository: coordinator.container.notificationRepository,
                        profile: coordinator.profile
                    ),
                    existingProfile: coordinator.profile,
                    onCompleted: coordinator.completeOnboarding
                )
            case .main:
                HomeRootView(coordinator: coordinator)
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.locale, coordinator.profile.language.locale)
        .tint(.blue)
        .task {
            guard didStart == false else {
                return
            }

            didStart = true
            await coordinator.start()
        }
        .onChange(of: deepLinkHandler.pendingLink) { _, newLink in
            handleDeepLink(newLink)
        }
    }

    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }

        switch link {
        case .settings:
            coordinator.showSettings = true
        case .onboarding:
            coordinator.rootFlow = .onboarding
        case .home:
            break
        case .insights:
            // Open insights view - can be expanded when insights screen gets navigation
            break
        case .recommendationDetail(let id):
            AnalyticsManager.shared.track(.recommendationViewed(id))
        }

        deepLinkHandler.clear()
    }
}

private struct HomeRootView: View {
    @Bindable var coordinator: AppCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @State private var homeViewModel: HomeViewModel
    @State private var showSettings = false

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        let name = coordinator.profile.savedLocations
            .first { $0.id == coordinator.profile.selectedLocationID }?
            .name ?? L10n.text("home_current_location")
        _homeViewModel = State(wrappedValue: HomeViewModel(
            loadHomeRecommendationUseCase: coordinator.container.loadHomeRecommendationUseCase,
            scheduleSmartNotificationsUseCase: coordinator.container.scheduleSmartNotificationsUseCase,
            preferencesRepository: coordinator.container.preferencesRepository,
            dateProvider: coordinator.container.dateProvider,
            activityWindowScoringEngine: coordinator.container.activityWindowScoringEngine,
            selectedLocationName: name
        ))
    }

    var body: some View {
        HomeView(
            viewModel: homeViewModel,
            savedLocations: savedLocationsBinding,
            selectedLocationID: selectedLocationIDBinding,
            onRecommendationLoaded: { recommendation in
                coordinator.updateRecommendation(recommendation)
            },
            onOpenSettings: { showSettings = true },
            onLocationsChanged: { locations, selectedID in
                Task {
                    var profile = coordinator.profile
                    profile.savedLocations = locations
                    profile.selectedLocationID = selectedID
                    do {
                        try await coordinator.container.updateUserPreferencesUseCase.execute(profile: profile)
                        coordinator.applyProfile(profile)
                    } catch {
                        AppLogger.persistence.error("Failed to save locations: \(error.localizedDescription)")
                    }
                }
            }
        )
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(
                    viewModel: SettingsViewModel(
                        profile: coordinator.profile,
                        updateUserPreferencesUseCase: coordinator.container.updateUserPreferencesUseCase,
                        onProfileSaved: coordinator.applyProfile,
                        onResetOnboarding: coordinator.resetToOnboarding,
                        onDeleteAllData: coordinator.deleteAllData
                    )
                )
            }
        }
        .onChange(of: coordinator.showSettings) { _, shouldShow in
            if shouldShow { showSettings = true }
        }
        .onChange(of: showSettings) { _, isPresented in
            if !isPresented { coordinator.dismissSettings() }
        }
        .onChange(of: coordinator.profile.language) { _, _ in
            Task { await homeViewModel.reloadForLanguageChange() }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else {
                return
            }

            Task { await homeViewModel.refreshWhenAppBecomesActive() }
        }
    }

    private var savedLocationsBinding: Binding<[SavedLocation]> {
        Binding(
            get: { coordinator.profile.savedLocations },
            set: { coordinator.profile.savedLocations = $0 }
        )
    }

    private var selectedLocationIDBinding: Binding<String> {
        Binding(
            get: { coordinator.profile.selectedLocationID },
            set: { coordinator.profile.selectedLocationID = $0 }
        )
    }
}

private extension AppLanguage {
    var locale: Locale {
        if let localeIdentifier {
            Locale(identifier: localeIdentifier)
        } else {
            .autoupdatingCurrent
        }
    }
}
