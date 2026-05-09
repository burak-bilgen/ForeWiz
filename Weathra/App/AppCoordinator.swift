import Combine
import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    enum RootFlow: Equatable {
        case launching
        case onboarding
        case main
    }

    let container: DependencyContainer

    @Published var rootFlow: RootFlow
    @Published var profile: UserComfortProfile = .default
    @Published var latestRecommendation: DailyRecommendation?
    @Published var showSettings = false
    @Published var showPaywall = false
    @Published var selectedTab = 0

    init(container: DependencyContainer, rootFlow: RootFlow = .launching) {
        self.container = container
        self.rootFlow = rootFlow
        L10n.configure(language: profile.language)
    }

    func start() async {
        AnalyticsManager.shared.track(.appLaunch)

        do {
            var loadedProfile = try await container.preferencesRepository.loadProfile()
            await container.subscriptionManager.refreshStatus()
            loadedProfile.subscriptionTier = container.subscriptionManager.tier
            L10n.configure(language: loadedProfile.language)
            profile = loadedProfile
            rootFlow = try await container.preferencesRepository.isOnboardingCompleted() ? .main : .onboarding
        } catch {
            L10n.configure(language: profile.language)
            rootFlow = .onboarding
        }
    }

    func completeOnboarding(profile: UserComfortProfile) async throws {
        try await container.completeOnboardingUseCase.execute(profile: profile)
        L10n.configure(language: profile.language)
        self.profile = profile
        AnalyticsManager.shared.track(.onboardingCompleted)
        rootFlow = .main
    }

    func applyProfile(_ profile: UserComfortProfile) {
        L10n.configure(language: profile.language)
        self.profile = profile
    }

    func updateRecommendation(_ recommendation: DailyRecommendation) {
        self.latestRecommendation = recommendation
    }

    func resetToOnboarding() {
        Task {
            try? await container.preferencesRepository.setOnboardingCompleted(false)
        }
        rootFlow = .onboarding
    }
}
