import Foundation

final class DefaultCompleteOnboardingUseCase: CompleteOnboardingUseCase {
    private let preferencesRepository: PreferencesRepository

    init(preferencesRepository: PreferencesRepository) {
        self.preferencesRepository = preferencesRepository
    }

    func execute(profile: UserComfortProfile) async throws {
        try await preferencesRepository.saveProfile(profile)
        try await preferencesRepository.setOnboardingCompleted(true)
    }
}
