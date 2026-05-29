import Foundation

@MainActor
@Observable
final class AppCoordinator {
    enum RootFlow: Equatable {
        case onboarding
        case main
    }

    let container: DependencyContainer

    var rootFlow: RootFlow
    var profile: UserComfortProfile = .default
    var latestRecommendation: DailyRecommendation?
    var showSettings = false
    var navigateToInsights = false
    var selectedRecommendationID: String?

    init(container: DependencyContainer, rootFlow: RootFlow = .onboarding) {
        self.container = container  
        self.rootFlow = rootFlow
    }

    func start() async {
        EventLogger.shared.track(.appLaunch)

        do {
            let loadedProfile = try await container.preferencesRepository.loadProfile()
            profile = loadedProfile
            L10n.configure(language: loadedProfile.language)
            rootFlow = try await container.preferencesRepository.isOnboardingCompleted() ? .main : .onboarding
        } catch {
            profile = .default
            L10n.configure(language: .english)
            rootFlow = .onboarding
        }
    }

    func completeOnboarding(profile: UserComfortProfile) async throws {
        try await container.completeOnboardingUseCase.execute(profile: profile)
        L10n.configure(language: profile.language)
        self.profile = profile
        EventLogger.shared.track(.onboardingCompleted)
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

    func dismissSettings() {
        showSettings = false
    }

    func deleteAllData() {
        Task {
            try? await container.preferencesRepository.deleteAll()
            try? await container.weatherCacheRepository.deleteAll()

            let defaults = Foundation.UserDefaults.standard
            let suite = Foundation.UserDefaults(suiteName: AppKeys.appGroupSuiteName)
            defaults.removeObject(forKey: AppKeys.UserDefaults.languageOverride)
            defaults.removeObject(forKey: AppKeys.UserDefaults.appTheme)
            defaults.removeObject(forKey: AppKeys.UserDefaults.appAccentColor)
            suite?.removeObject(forKey: AppKeys.UserDefaults.languageOverride)

            profile = .default
            rootFlow = .onboarding
        }
    }
}


extension Notification.Name {
    static let appLanguageDidChange = AppKeys.NotificationName.appLanguageDidChange
}
