import Combine
import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    enum RootFlow: Equatable {
        case onboarding
        case main
    }

    let container: DependencyContainer

    @Published private(set) var rootFlow: RootFlow

    init(container: DependencyContainer, rootFlow: RootFlow = .onboarding) {
        self.container = container
        self.rootFlow = rootFlow
    }

    func completeOnboarding() {
        rootFlow = .main
    }

    func resetToOnboarding() {
        rootFlow = .onboarding
    }
}
