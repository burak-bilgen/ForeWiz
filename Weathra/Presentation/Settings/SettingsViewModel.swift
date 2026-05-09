import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: UserComfortProfile
    @Published private(set) var saveMessage: String?
    @Published var showPaywall = false

    private let updateUserPreferencesUseCase: UpdateUserPreferencesUseCase
    let subscriptionManager: StoreKitSubscriptionManager
    private let onProfileSaved: (UserComfortProfile) -> Void
    private let onResetOnboarding: (() -> Void)?
    private var cancellables: Set<AnyCancellable> = []
    private var pendingSave: Task<Void, Never>?
    private let saveSubject = PassthroughSubject<UserComfortProfile, Never>()

    init(
        profile: UserComfortProfile,
        updateUserPreferencesUseCase: UpdateUserPreferencesUseCase,
        subscriptionManager: StoreKitSubscriptionManager,
        onProfileSaved: @escaping (UserComfortProfile) -> Void,
        onResetOnboarding: (() -> Void)? = nil
    ) {
        self.profile = profile
        self.updateUserPreferencesUseCase = updateUserPreferencesUseCase
        self.subscriptionManager = subscriptionManager
        self.onProfileSaved = onProfileSaved
        self.onResetOnboarding = onResetOnboarding

        subscriptionManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        saveSubject
            .debounce(for: .milliseconds(800), scheduler: DispatchQueue.main)
            .sink { [weak self] profile in
                self?.performSave(profile: profile)
            }
            .store(in: &cancellables)
    }

    var isPremium: Bool {
        subscriptionManager.isPremium
    }

    func save() {
        saveSubject.send(profile)
    }

    private func performSave(profile: UserComfortProfile) {
        pendingSave?.cancel()
        pendingSave = Task {
            do {
                try await updateUserPreferencesUseCase.execute(profile: profile)
                onProfileSaved(profile)
                saveMessage = L10n.text("settings_save_success")
                HapticManager.success()
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                if !Task.isCancelled {
                    saveMessage = nil
                }
            } catch {
                if !Task.isCancelled {
                    saveMessage = AppError.persistenceFailed.userMessage
                    HapticManager.error()
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    saveMessage = nil
                }
            }
        }
    }

    func resetOnboarding() {
        onResetOnboarding?()
    }

    func openPaywall() {
        HapticManager.medium()
        showPaywall = true
    }
}
