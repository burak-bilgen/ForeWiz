import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: UserComfortProfile
    @Published private(set) var saveMessage: String?

    private let updateUserPreferencesUseCase: UpdateUserPreferencesUseCase
    private let onProfileSaved: (UserComfortProfile) -> Void
    private let onResetOnboarding: (() -> Void)?

    init(
        profile: UserComfortProfile,
        updateUserPreferencesUseCase: UpdateUserPreferencesUseCase,
        onProfileSaved: @escaping (UserComfortProfile) -> Void,
        onResetOnboarding: (() -> Void)? = nil
    ) {
        self.profile = profile
        self.updateUserPreferencesUseCase = updateUserPreferencesUseCase
        self.onProfileSaved = onProfileSaved
        self.onResetOnboarding = onResetOnboarding
    }

    func save() {
        let profile = profile
        Task {
            do {
                try await updateUserPreferencesUseCase.execute(profile: profile)
                onProfileSaved(profile)
                saveMessage = "✓ Tercihler kaydedildi"
            } catch {
                saveMessage = AppError.persistenceFailed.userMessage
            }
        }
    }

    func resetOnboarding() {
        onResetOnboarding?()
    }
}

