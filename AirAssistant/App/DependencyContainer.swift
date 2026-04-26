import Foundation

@MainActor
final class DependencyContainer {
    let environment: AppEnvironment
    let dateProvider: DateProvider
    let activityWindowScoringEngine: ActivityWindowScoringEngine
    let outfitDecisionEngine: OutfitDecisionEngine
    let weatherDecisionEngine: WeatherDecisionEngine
    let notificationPlanningEngine: NotificationPlanningEngine

    init(
        environment: AppEnvironment,
        dateProvider: DateProvider,
        activityWindowScoringEngine: ActivityWindowScoringEngine,
        outfitDecisionEngine: OutfitDecisionEngine,
        weatherDecisionEngine: WeatherDecisionEngine,
        notificationPlanningEngine: NotificationPlanningEngine
    ) {
        self.environment = environment
        self.dateProvider = dateProvider
        self.activityWindowScoringEngine = activityWindowScoringEngine
        self.outfitDecisionEngine = outfitDecisionEngine
        self.weatherDecisionEngine = weatherDecisionEngine
        self.notificationPlanningEngine = notificationPlanningEngine
    }

    static func live() -> DependencyContainer {
        let dateProvider = SystemDateProvider()
        let activityEngine = DefaultActivityWindowScoringEngine()
        let outfitEngine = DefaultOutfitDecisionEngine()
        let weatherEngine = DefaultWeatherDecisionEngine(
            activityWindowScoringEngine: activityEngine,
            outfitDecisionEngine: outfitEngine
        )
        let notificationEngine = DefaultNotificationPlanningEngine()

        return DependencyContainer(
            environment: .production,
            dateProvider: dateProvider,
            activityWindowScoringEngine: activityEngine,
            outfitDecisionEngine: outfitEngine,
            weatherDecisionEngine: weatherEngine,
            notificationPlanningEngine: notificationEngine
        )
    }
}
