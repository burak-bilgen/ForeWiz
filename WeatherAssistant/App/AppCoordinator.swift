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

    @Published private(set) var rootFlow: RootFlow
    @Published private(set) var profile: UserComfortProfile = .default

    init(container: DependencyContainer, rootFlow: RootFlow = .launching) {
        self.container = container
        self.rootFlow = rootFlow
    }

    func start() async {
        do {
            profile = try await container.preferencesRepository.loadProfile()
            rootFlow = try await container.preferencesRepository.isOnboardingCompleted() ? .main : .onboarding
        } catch {
            rootFlow = .onboarding
        }
    }

    func completeOnboarding(profile: UserComfortProfile) async throws {
        try await container.completeOnboardingUseCase.execute(profile: profile)
        self.profile = profile
        rootFlow = .main
    }

    func applyProfile(_ profile: UserComfortProfile) {
        self.profile = profile
    }

    func resetToOnboarding() {
        Task {
            try? await container.preferencesRepository.setOnboardingCompleted(false)
        }
        rootFlow = .onboarding
    }
}
