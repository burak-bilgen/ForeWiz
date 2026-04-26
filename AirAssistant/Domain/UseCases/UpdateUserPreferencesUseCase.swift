import Foundation

protocol UpdateUserPreferencesUseCase {
    func execute(profile: UserComfortProfile) async throws
}
