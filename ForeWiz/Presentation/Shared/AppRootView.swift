import SwiftUI

struct AppRootView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var deepLinkHandler: DeepLinkHandler
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
        .preferredColorScheme(coordinator.profile.appearance.colorScheme)
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
        case .insights, .home, .recommendationDetail:
            break
        }

        deepLinkHandler.clear()
    }
}

private struct HomeRootView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var homeViewModel: HomeViewModel
    @State private var showSettings = false

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        let name = coordinator.profile.savedLocations
            .first { $0.id == coordinator.profile.selectedLocationID }?
            .name ?? L10n.text("home_current_location")
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
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
            savedLocations: $coordinator.profile.savedLocations,
            selectedLocationID: $coordinator.profile.selectedLocationID,
            onRecommendationLoaded: { recommendation in
                coordinator.updateRecommendation(recommendation)
            },
            onOpenSettings: { showSettings = true }
        )
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(
                    viewModel: SettingsViewModel(
                        profile: coordinator.profile,
                        updateUserPreferencesUseCase: coordinator.container.updateUserPreferencesUseCase,
                        onProfileSaved: coordinator.applyProfile,
                        onResetOnboarding: coordinator.resetToOnboarding
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

private extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
