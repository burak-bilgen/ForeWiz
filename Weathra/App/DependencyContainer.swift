import Foundation

@MainActor
final class DependencyContainer {
    let environment: AppEnvironment
    let dateProvider: DateProvider
    let activityWindowScoringEngine: ActivityWindowScoringEngine
    let outfitDecisionEngine: OutfitDecisionEngine
    let weatherDecisionEngine: WeatherDecisionEngine
    let notificationPlanningEngine: NotificationPlanningEngine
    let locationRepository: LocationRepository
    let weatherRepository: WeatherRepository
    let weatherCacheRepository: WeatherCacheRepository
    let preferencesRepository: PreferencesRepository
    let notificationRepository: NotificationRepository
    let loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase
    let completeOnboardingUseCase: CompleteOnboardingUseCase
    let updateUserPreferencesUseCase: UpdateUserPreferencesUseCase
    let scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase

    init(
        environment: AppEnvironment,
        dateProvider: DateProvider,
        activityWindowScoringEngine: ActivityWindowScoringEngine,
        outfitDecisionEngine: OutfitDecisionEngine,
        weatherDecisionEngine: WeatherDecisionEngine,
        notificationPlanningEngine: NotificationPlanningEngine,
        locationRepository: LocationRepository,
        weatherRepository: WeatherRepository,
        weatherCacheRepository: WeatherCacheRepository,
        preferencesRepository: PreferencesRepository,
        notificationRepository: NotificationRepository,
        loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase,
        completeOnboardingUseCase: CompleteOnboardingUseCase,
        updateUserPreferencesUseCase: UpdateUserPreferencesUseCase,
        scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase
    ) {
        self.environment = environment
        self.dateProvider = dateProvider
        self.activityWindowScoringEngine = activityWindowScoringEngine
        self.outfitDecisionEngine = outfitDecisionEngine
        self.weatherDecisionEngine = weatherDecisionEngine
        self.notificationPlanningEngine = notificationPlanningEngine
        self.locationRepository = locationRepository
        self.weatherRepository = weatherRepository
        self.weatherCacheRepository = weatherCacheRepository
        self.preferencesRepository = preferencesRepository
        self.notificationRepository = notificationRepository
        self.loadHomeRecommendationUseCase = loadHomeRecommendationUseCase
        self.completeOnboardingUseCase = completeOnboardingUseCase
        self.updateUserPreferencesUseCase = updateUserPreferencesUseCase
        self.scheduleSmartNotificationsUseCase = scheduleSmartNotificationsUseCase
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
        let preferencesRepository = SwiftDataPreferencesRepository()
        let weatherCacheRepository = SwiftDataWeatherCacheRepository()
        let locationRepository = CoreLocationRepository()
        let weatherRepository = WeatherKitWeatherRepository(dateProvider: dateProvider)
        let notificationRepository = UserNotificationRepository()
        let loadHomeRecommendationUseCase = DefaultLoadHomeRecommendationUseCase(
            locationRepository: locationRepository,
            weatherRepository: weatherRepository,
            weatherCacheRepository: weatherCacheRepository,
            preferencesRepository: preferencesRepository,
            weatherDecisionEngine: weatherEngine,
            dateProvider: dateProvider
        )
        let completeOnboardingUseCase = DefaultCompleteOnboardingUseCase(
            preferencesRepository: preferencesRepository
        )
        let updateUserPreferencesUseCase = DefaultUpdateUserPreferencesUseCase(
            preferencesRepository: preferencesRepository
        )
        let scheduleSmartNotificationsUseCase = DefaultScheduleSmartNotificationsUseCase(
            notificationRepository: notificationRepository,
            notificationPlanningEngine: notificationEngine,
            dateProvider: dateProvider
        )

        return DependencyContainer(
            environment: .production,
            dateProvider: dateProvider,
            activityWindowScoringEngine: activityEngine,
            outfitDecisionEngine: outfitEngine,
            weatherDecisionEngine: weatherEngine,
            notificationPlanningEngine: notificationEngine,
            locationRepository: locationRepository,
            weatherRepository: weatherRepository,
            weatherCacheRepository: weatherCacheRepository,
            preferencesRepository: preferencesRepository,
            notificationRepository: notificationRepository,
            loadHomeRecommendationUseCase: loadHomeRecommendationUseCase,
            completeOnboardingUseCase: completeOnboardingUseCase,
            updateUserPreferencesUseCase: updateUserPreferencesUseCase,
            scheduleSmartNotificationsUseCase: scheduleSmartNotificationsUseCase
        )
    }
}
