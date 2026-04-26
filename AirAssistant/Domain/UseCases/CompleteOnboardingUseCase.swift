import Foundation

protocol CompleteOnboardingUseCase {
    func execute(profile: UserComfortProfile) async throws
}
