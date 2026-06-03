import Foundation
import SwiftData
import WizPathKit

@MainActor
final class DependencyContainer {
    static var shared: DependencyContainer {
        guard let instance else {
            preconditionFailure("DependencyContainer not initialized. Call DependencyContainer.init() first.")
        }
        return instance
    }
    private static var instance: DependencyContainer?

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
    
    // MARK: - Health
    let healthRepository: HealthRepository

    // MARK: - Services
    let severeWeatherAlertService: SevereWeatherAlertService
    
    // MARK: - WizPath
    let wizPathService: WizPathService
    let locationService: LocationService
    
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
        healthRepository: HealthRepository,
        loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase,
        completeOnboardingUseCase: CompleteOnboardingUseCase,
        updateUserPreferencesUseCase: UpdateUserPreferencesUseCase,
        scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase,
        homeViewStateFactory: HomeViewStateFactory,
        severeWeatherAlertService: SevereWeatherAlertService,
        weatherGradientService: WeatherGradientService,
        retryPolicy: NetworkRetryPolicy,
        wizPathService: WizPathService,
        locationService: LocationService
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
        self.healthRepository = healthRepository
        self.loadHomeRecommendationUseCase = loadHomeRecommendationUseCase
        self.completeOnboardingUseCase = completeOnboardingUseCase
        self.updateUserPreferencesUseCase = updateUserPreferencesUseCase
        self.scheduleSmartNotificationsUseCase = scheduleSmartNotificationsUseCase
        self.homeViewStateFactory = homeViewStateFactory
        self.weatherGradientService = weatherGradientService
        self.retryPolicy = retryPolicy
        self.severeWeatherAlertService = severeWeatherAlertService
        self.wizPathService = wizPathService
        self.locationService = locationService
        Self.instance = self
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
        let severeWeatherAlertService = SevereWeatherAlertService.shared
        
        let locationService = LocationService(timeout: 8.0)
        let wizPathLocationSource = WizPathLocationServiceAdapter(locationService: locationService)
        let wizPathWeatherSource = WizPathWeatherServiceAdapter(weatherRepository: weatherRepository, dateProvider: dateProvider)
        let wizPathService = WizPathService(
            weatherRepository: wizPathWeatherSource,
            locationRepository: wizPathLocationSource
        )
        
        // Prepare haptic engine on launch
        HapticEngine.shared.prepare()
        
        let briefingService = WeatherBriefingService()

        let loadHomeRecommendationUseCase = DefaultLoadHomeRecommendationUseCase(
            locationRepository: locationRepository,
            weatherRepository: weatherRepository,
            weatherCacheRepository: weatherCacheRepository,
            preferencesRepository: preferencesRepository,
            weatherDecisionEngine: weatherEngine,
            dateProvider: dateProvider,
            weatherBriefingService: briefingService
        )
        let completeOnboardingUseCase = DefaultCompleteOnboardingUseCase(
            preferencesRepository: preferencesRepository
        )
        let updateUserPreferencesUseCase = DefaultUpdateUserPreferencesUseCase(
            preferencesRepository: preferencesRepository
        )
        let throttlingService = NotificationThrottlingService()

        let scheduleSmartNotificationsUseCase = DefaultScheduleSmartNotificationsUseCase(
            notificationRepository: notificationRepository,
            notificationPlanningEngine: notificationEngine,
            dateProvider: dateProvider,
            throttlingService: throttlingService
        )

        let healthRepository = MockHealthRepository()

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
            healthRepository: healthRepository,
            loadHomeRecommendationUseCase: loadHomeRecommendationUseCase,
            completeOnboardingUseCase: completeOnboardingUseCase,
            updateUserPreferencesUseCase: updateUserPreferencesUseCase,
            scheduleSmartNotificationsUseCase: scheduleSmartNotificationsUseCase,
            homeViewStateFactory: homeViewStateFactory,
            severeWeatherAlertService: severeWeatherAlertService,
            weatherGradientService: weatherGradientService,
            retryPolicy: retryPolicy,
            wizPathService: wizPathService,
            locationService: locationService
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
        let locationService = LocationService(timeout: 8.0) // Hardened with timeout
        let locationRepository = locationService as LocationRepository
        let weatherRepository = WeatherKitWeatherRepository(dateProvider: dateProvider)
        let notificationRepository = UserNotificationRepository()
        let homeViewStateFactory = HomeViewStateFactory(
            dateProvider: dateProvider,
            activityWindowScoringEngine: activityEngine
        )
        let weatherGradientService = WeatherGradientService.shared
        let retryPolicy = NetworkRetryPolicy.aggressive // More retries for production
        let severeWeatherAlertService = SevereWeatherAlertService.shared
        
        let wizPathLocationSource = WizPathLocationServiceAdapter(locationService: locationService)
        let wizPathWeatherSource = WizPathWeatherServiceAdapter(
            weatherRepository: weatherRepository,
            dateProvider: dateProvider
        )
        let wizPathService = WizPathService(
            weatherRepository: wizPathWeatherSource,
            locationRepository: wizPathLocationSource
        )
        
        // Prepare haptic engine on launch
        HapticEngine.shared.prepare()
        
        let briefingService = WeatherBriefingService()

        let loadHomeRecommendationUseCase = DefaultLoadHomeRecommendationUseCase(
            locationRepository: locationRepository,
            weatherRepository: weatherRepository,
            weatherCacheRepository: weatherCacheRepository,
            preferencesRepository: preferencesRepository,
            weatherDecisionEngine: weatherEngine,
            dateProvider: dateProvider,
            weatherBriefingService: briefingService
        )
        let completeOnboardingUseCase = DefaultCompleteOnboardingUseCase(
            preferencesRepository: preferencesRepository
        )
        let updateUserPreferencesUseCase = DefaultUpdateUserPreferencesUseCase(
            preferencesRepository: preferencesRepository
        )
        let throttlingService = NotificationThrottlingService()

        let scheduleSmartNotificationsUseCase = DefaultScheduleSmartNotificationsUseCase(
            notificationRepository: notificationRepository,
            notificationPlanningEngine: notificationEngine,
            dateProvider: dateProvider,
            throttlingService: throttlingService
        )

        let healthRepository = HealthKitRepository()

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
            healthRepository: healthRepository,
            loadHomeRecommendationUseCase: loadHomeRecommendationUseCase,
            completeOnboardingUseCase: completeOnboardingUseCase,
            updateUserPreferencesUseCase: updateUserPreferencesUseCase,
            scheduleSmartNotificationsUseCase: scheduleSmartNotificationsUseCase,
            homeViewStateFactory: homeViewStateFactory,
            severeWeatherAlertService: severeWeatherAlertService,
            weatherGradientService: weatherGradientService,
            retryPolicy: retryPolicy,
            wizPathService: wizPathService,
            locationService: locationService
        )
    }
}