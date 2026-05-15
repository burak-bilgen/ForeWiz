import Foundation

@MainActor
@Observable
final class SettingsViewModel {
    var profile: UserComfortProfile
    private(set) var saveMessage: String?

    private let updateUserPreferencesUseCase: UpdateUserPreferencesUseCase
    private let onProfileSaved: (UserComfortProfile) -> Void
    private let onResetOnboarding: (() -> Void)?
    private let onDeleteAllData: (() -> Void)?
    private var pendingSave: Task<Void, Never>?
    private var lastSaveTime: Date = .distantPast

    init(
        profile: UserComfortProfile,
        updateUserPreferencesUseCase: UpdateUserPreferencesUseCase,
        onProfileSaved: @escaping (UserComfortProfile) -> Void,
        onResetOnboarding: (() -> Void)? = nil,
        onDeleteAllData: (() -> Void)? = nil
    ) {
        self.profile = profile
        self.updateUserPreferencesUseCase = updateUserPreferencesUseCase
        self.onProfileSaved = onProfileSaved
        self.onResetOnboarding = onResetOnboarding
        self.onDeleteAllData = onDeleteAllData
    }

    var isPremium: Bool {
        FeatureGate.currentTier == .premium
    }

    func save() {
        pendingSave?.cancel()
        lastSaveTime = Date()
        pendingSave = Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            await performSave(profile: profile)
        }
    }

    private func performSave(profile: UserComfortProfile) async {
        do {
            try await updateUserPreferencesUseCase.execute(profile: profile)
            onProfileSaved(profile)
            saveMessage = L10n.text("settings_save_success")
            HapticEngine.shared.success()
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if !Task.isCancelled {
                saveMessage = nil
            }
        } catch {
            if !Task.isCancelled {
                saveMessage = AppError.persistenceFailed.userMessage
                HapticEngine.shared.error()
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                saveMessage = nil
            }
        }
    }

    func resetOnboarding() {
        onResetOnboarding?()
    }

    func deleteAllData() {
        onDeleteAllData?()
    }

    func exportData() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(profile),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}
