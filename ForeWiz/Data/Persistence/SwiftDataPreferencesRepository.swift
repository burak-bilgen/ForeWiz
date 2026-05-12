import Foundation
import SwiftData

final class SwiftDataPreferencesRepository: PreferencesRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadProfile() async throws -> UserComfortProfile {
        let descriptor = FetchDescriptor<UserPreferencesModel>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let preferences = try modelContext.fetch(descriptor)
        
        guard let model = preferences.first else {
            return .default
        }
        
        return model.toProfile()
    }

    func saveProfile(_ profile: UserComfortProfile) async throws {
        let descriptor = FetchDescriptor<UserPreferencesModel>()
        let existing = try modelContext.fetch(descriptor)
        
        if let model = existing.first {
            model.update(from: profile)
        } else {
            let model = UserPreferencesModel(
                temperatureSensitivity: profile.temperatureSensitivity,
                preferredActivities: Array(profile.preferredActivities),
                quietHours: profile.quietHours,
                onboardingCompleted: true,
                preferredLanguage: profile.language,
                preferredAppearance: profile.appearance
            )
            model.update(from: profile)
            modelContext.insert(model)
        }
        
        try modelContext.save()
    }

    func isOnboardingCompleted() async throws -> Bool {
        let descriptor = FetchDescriptor<UserPreferencesModel>()
        let preferences = try modelContext.fetch(descriptor)
        return preferences.first?.onboardingCompleted ?? false
    }

    func setOnboardingCompleted(_ completed: Bool) async throws {
        let descriptor = FetchDescriptor<UserPreferencesModel>()
        let existing = try modelContext.fetch(descriptor)
        
        if let model = existing.first {
            model.onboardingCompleted = completed
        } else {
            let model = UserPreferencesModel(
                temperatureSensitivity: .normal,
                preferredActivities: [.goingOutside, .walking],
                quietHours: nil,
                onboardingCompleted: completed
            )
            modelContext.insert(model)
        }
        
        try modelContext.save()
    }

    func deleteAll() async throws {
        let descriptor = FetchDescriptor<UserPreferencesModel>()
        let models = try modelContext.fetch(descriptor)
        models.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}
