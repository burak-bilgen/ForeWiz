import Foundation
import SwiftData

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
    
    // MARK: - New Architecture Components
    let homeViewStateFactory: HomeViewStateFactory
    let weatherGradientService: WeatherGradientService
    let retryPolicy: NetworkRetryPolicy

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
        scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase,
        homeViewStateFactory: HomeViewStateFactory,
        weatherGradientService: WeatherGradientService,
        retryPolicy: NetworkRetryPolicy
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
        self.homeViewStateFactory = homeViewStateFactory
        self.weatherGradientService = weatherGradientService
        self.retryPolicy = retryPolicy
    }

    static func simulator(modelContext: ModelContext) -> DependencyContainer {
        let dateProvider = SystemDateProvider()
        let activityEngine = DefaultActivityWindowScoringEngine()
        let outfitEngine = DefaultOutfitDecisionEngine()
        let weatherEngine = DefaultWeatherDecisionEngine(
            activityWindowScoringEngine: activityEngine,
            outfitDecisionEngine: outfitEngine
        )
        let notificationEngine = DefaultNotificationPlanningEngine()
        let preferencesRepository = SwiftDataPreferencesRepository(modelContext: modelContext)
        let weatherCacheRepository = SwiftDataWeatherCacheRepository(modelContext: modelContext)
        
        // MARK: - New Architecture Services
        let locationRepository = MockLocationRepository()
        let weatherRepository = MockWeatherRepository(dateProvider: dateProvider)
        let notificationRepository = UserNotificationRepository()
        let homeViewStateFactory = HomeViewStateFactory(
            dateProvider: dateProvider,
            activityWindowScoringEngine: activityEngine
        )
        let weatherGradientService = WeatherGradientService.shared
        let retryPolicy = NetworkRetryPolicy.default
        
        // Prepare haptic engine on launch
        HapticEngine.shared.prepare()
        
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
            environment: .simulator,
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
            scheduleSmartNotificationsUseCase: scheduleSmartNotificationsUseCase,
            homeViewStateFactory: homeViewStateFactory,
            weatherGradientService: weatherGradientService,
            retryPolicy: retryPolicy
        )
    }

    static func live(modelContext: ModelContext) -> DependencyContainer {
        let dateProvider = SystemDateProvider()
        let activityEngine = DefaultActivityWindowScoringEngine()
        let outfitEngine = DefaultOutfitDecisionEngine()
        let weatherEngine = DefaultWeatherDecisionEngine(
            activityWindowScoringEngine: activityEngine,
            outfitDecisionEngine: outfitEngine
        )
        let notificationEngine = DefaultNotificationPlanningEngine()
        let preferencesRepository = SwiftDataPreferencesRepository(modelContext: modelContext)
        let weatherCacheRepository = SwiftDataWeatherCacheRepository(modelContext: modelContext)
        
        // MARK: - New Architecture Services (Production)
        let locationRepository = LocationService(timeout: 8.0) // Hardened with timeout
        let weatherRepository = WeatherKitWeatherRepository(dateProvider: dateProvider)
        let notificationRepository = UserNotificationRepository()
        let homeViewStateFactory = HomeViewStateFactory(
            dateProvider: dateProvider,
            activityWindowScoringEngine: activityEngine
        )
        let weatherGradientService = WeatherGradientService.shared
        let retryPolicy = NetworkRetryPolicy.aggressive // More retries for production
        
        // Prepare haptic engine on launch
        HapticEngine.shared.prepare()
        
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
            scheduleSmartNotificationsUseCase: scheduleSmartNotificationsUseCase,
            homeViewStateFactory: homeViewStateFactory,
            weatherGradientService: weatherGradientService,
            retryPolicy: retryPolicy
        )
    }
}