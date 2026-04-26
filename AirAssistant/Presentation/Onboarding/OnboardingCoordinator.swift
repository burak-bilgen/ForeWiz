@MainActor
final class OnboardingCoordinator {
    private let completed: () -> Void

    init(completed: @escaping () -> Void) {
        self.completed = completed
    }

    func finish() {
        completed()
    }
}
