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
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            guard coordinator.rootFlow == .main else { return }
            let code = L10n.currentLanguageCode
            coordinator.profile.language = code == "tr" ? .turkish : .english
            Task {
                do {
                    try await coordinator.container.updateUserPreferencesUseCase.execute(profile: coordinator.profile)
                } catch {
                    AppLogger.persistence.error("Failed to save language: \(error.localizedDescription)")
                }
            }
        }
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
            coordinator.rootFlow = .main
        case .insights:
            coordinator.rootFlow = .main
            coordinator.navigateToInsights = true
            EventLogger.shared.track(.insightsViewed)
        case .recommendationDetail(let id):
            coordinator.rootFlow = .main
            coordinator.selectedRecommendationID = id
            EventLogger.shared.track(.recommendationViewed(id))
        }

        deepLinkHandler.clear()
    }
}

private struct HomeRootView: View {
    @Bindable var coordinator: AppCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @State private var homeViewModel: HomeViewModel

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        let selectedLocation = coordinator.profile.savedLocations
            .first { $0.id == coordinator.profile.selectedLocationID }
        let name = selectedLocation?.name ?? L10n.text("home_current_location")
        _homeViewModel = State(wrappedValue: HomeViewModel(
            loadHomeRecommendationUseCase: coordinator.container.loadHomeRecommendationUseCase,
            scheduleSmartNotificationsUseCase: coordinator.container.scheduleSmartNotificationsUseCase,
            preferencesRepository: coordinator.container.preferencesRepository,
            homeViewStateFactory: coordinator.container.homeViewStateFactory,
            selectedLocationName: name,
            selectedLocation: selectedLocation
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
            },
            wizPathService: coordinator.container.wizPathService
        )
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
