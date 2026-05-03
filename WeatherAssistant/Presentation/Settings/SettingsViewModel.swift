import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: UserComfortProfile
    @Published private(set) var saveMessage: String?

    private let updateUserPreferencesUseCase: UpdateUserPreferencesUseCase
    private let onProfileSaved: (UserComfortProfile) -> Void

    init(
        profile: UserComfortProfile,
        updateUserPreferencesUseCase: UpdateUserPreferencesUseCase,
        onProfileSaved: @escaping (UserComfortProfile) -> Void
    ) {
        self.profile = profile
        self.updateUserPreferencesUseCase = updateUserPreferencesUseCase
        self.onProfileSaved = onProfileSaved
    }

    func save() {
        let profile = profile
        Task {
            do {
                try await updateUserPreferencesUseCase.execute(profile: profile)
                onProfileSaved(profile)
                saveMessage = "Kaydedildi"
            } catch {
                saveMessage = AppError.persistenceFailed.userMessage
            }
        }
    }
}
