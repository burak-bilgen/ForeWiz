import Foundation

protocol WidgetRepository {
    func save(recommendation: DailyRecommendation) throws
    func loadLatest() throws -> DailyRecommendation?
}

final class SharedWidgetRepository: WidgetRepository {
    private let userDefaults: UserDefaults?
    private let key = "weathra_latest_recommendation"

    init(suiteName: String = "group.weathra") {
        self.userDefaults = UserDefaults(suiteName: suiteName)
    }

    func save(recommendation: DailyRecommendation) throws {
        guard let userDefaults else {
            throw AppError.persistenceFailed
        }

        let data = try JSONEncoder().encode(recommendation)
        userDefaults.set(data, forKey: key)
        
        // Tells WidgetKit to reload the timeline
        // Using a NotificationCenter isn't direct for WidgetKit, but since we can't import WidgetKit in Data layer directly without tying it,
        // we will leave WidgetCenter.shared.reloadAllTimelines() to the Presentation/App layer if needed, or just let UserDefaults do its job.
    }

    func loadLatest() throws -> DailyRecommendation? {
        guard let userDefaults, let data = userDefaults.data(forKey: key) else {
            return nil
        }

        return try JSONDecoder().decode(DailyRecommendation.self, from: data)
    }
}
