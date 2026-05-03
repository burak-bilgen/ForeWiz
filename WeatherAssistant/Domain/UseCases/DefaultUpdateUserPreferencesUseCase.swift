import Foundation

final class DefaultUpdateUserPreferencesUseCase: UpdateUserPreferencesUseCase {
    private let preferencesRepository: PreferencesRepository

    init(preferencesRepository: PreferencesRepository) {
        self.preferencesRepository = preferencesRepository
    }

    func execute(profile: UserComfortProfile) async throws {
        try await preferencesRepository.saveProfile(profile)
    }
}
