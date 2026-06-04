import Testing
import Foundation
import SwiftData
@testable import ForeWiz

@MainActor
@Suite("Weather Cache Repository Tests")
struct WeatherCacheRepositoryTests {

    @Test("Cache loads nil when no data exists")
    func testLoadLatestReturnsNilWhenEmpty() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WeatherSnapshotModel.self, configurations: config)
        let context = ModelContext(container)

        let repository = SwiftDataWeatherCacheRepository(modelContext: context)

        let result = try await repository.loadLatest()

        #expect(result == nil)
    }

    @Test("Cache saves and loads weather snapshot")
    func testSaveAndLoad() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WeatherSnapshotModel.self, configurations: config)
        let context = ModelContext(container)

        let repository = SwiftDataWeatherCacheRepository(modelContext: context)

        let snapshot = WeatherSnapshot(
            location: LocationCoordinate(latitude: 41.0, longitude: 29.0),
            current: CurrentWeatherPoint(
                date: Date(),
                temperatureCelsius: 25.0,
                apparentTemperatureCelsius: 27.0,
                humidity: 0.6,
                windSpeedKph: 10.0,
                precipitationChance: 0.1,
                precipitationAmountMm: 0.0,
                uvIndex: 5,
                conditionCode: "sunny",
                isDaylight: true,
                severeWeatherRisk: nil
            ),
            hourly: [],
            daily: [],
            fetchedAt: Date(),
            attribution: nil
        )

        try await repository.save(snapshot)

        let loaded = try await repository.loadLatest()

        #expect(loaded != nil)
        #expect(loaded?.location.latitude == 41.0)
        #expect(loaded?.location.longitude == 29.0)
        #expect(loaded?.current.temperatureCelsius == 25.0)
    }

    @Test("Cache expires old entries")
    func testCacheExpiration() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WeatherSnapshotModel.self, configurations: config)
        let context = ModelContext(container)

        let policy = WeatherCachePolicy(freshInterval: 1, usableInterval: 2)
        let repository = SwiftDataWeatherCacheRepository(modelContext: context, cachePolicy: policy)

        let oldSnapshot = WeatherSnapshot(
            location: LocationCoordinate(latitude: 41.0, longitude: 29.0),
            current: CurrentWeatherPoint(
                date: Date().addingTimeInterval(-3600),
                temperatureCelsius: 25.0,
                apparentTemperatureCelsius: 27.0,
                humidity: 0.6,
                windSpeedKph: 10.0,
                precipitationChance: 0.1,
                precipitationAmountMm: 0.0,
                uvIndex: 5,
                conditionCode: "sunny",
                isDaylight: true,
                severeWeatherRisk: nil
            ),
            hourly: [],
            daily: [],
            fetchedAt: Date().addingTimeInterval(-7200),
            attribution: nil
        )

        try await repository.save(oldSnapshot)

        let loaded = try await repository.loadLatest()

        #expect(loaded == nil)
    }

    @Test("Cache overwrites existing data")
    func testCacheOverwrite() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WeatherSnapshotModel.self, configurations: config)
        let context = ModelContext(container)

        let repository = SwiftDataWeatherCacheRepository(modelContext: context)

        let snapshot1 = WeatherSnapshot(
            location: LocationCoordinate(latitude: 41.0, longitude: 29.0),
            current: CurrentWeatherPoint(
                date: Date(),
                temperatureCelsius: 25.0,
                apparentTemperatureCelsius: 27.0,
                humidity: 0.6,
                windSpeedKph: 10.0,
                precipitationChance: 0.1,
                precipitationAmountMm: 0.0,
                uvIndex: 5,
                conditionCode: "sunny",
                isDaylight: true,
                severeWeatherRisk: nil
            ),
            hourly: [],
            daily: [],
            fetchedAt: Date(),
            attribution: nil
        )

        let snapshot2 = WeatherSnapshot(
            location: LocationCoordinate(latitude: 40.0, longitude: 28.0),
            current: CurrentWeatherPoint(
                date: Date(),
                temperatureCelsius: 30.0,
                apparentTemperatureCelsius: 32.0,
                humidity: 0.7,
                windSpeedKph: 15.0,
                precipitationChance: 0.2,
                precipitationAmountMm: 0.0,
                uvIndex: 7,
                conditionCode: "cloudy",
                isDaylight: true,
                severeWeatherRisk: nil
            ),
            hourly: [],
            daily: [],
            fetchedAt: Date(),
            attribution: nil
        )

        try await repository.save(snapshot1)
        try await repository.save(snapshot2)

        let loaded = try await repository.loadLatest()

        #expect(loaded?.location.latitude == 40.0)
        #expect(loaded?.current.temperatureCelsius == 30.0)
    }
}

@Suite("Weather Cache Policy Tests")
struct WeatherCachePolicyTests {

    @Test("Fresh data is detected correctly")
    func testFreshData() {
        let policy = WeatherCachePolicy()
        let now = Date()
        let freshDate = now.addingTimeInterval(-600)

        let freshness = policy.freshness(for: freshDate, now: now)

        #expect(freshness == .fresh)
    }

    @Test("Stale but usable data is detected correctly")
    func testStaleData() {
        let policy = WeatherCachePolicy(freshInterval: 1200, usableInterval: 18000)
        let now = Date()
        let staleDate = now.addingTimeInterval(-3600)

        let freshness = policy.freshness(for: staleDate, now: now)

        #expect(freshness == .staleUsable)
    }

    @Test("Expired data is detected correctly")
    func testExpiredData() {
        let policy = WeatherCachePolicy()
        let now = Date()
        let expiredDate = now.addingTimeInterval(-21601)

        let freshness = policy.freshness(for: expiredDate, now: now)

        #expect(freshness == .expired)
    }
}

@MainActor
@Suite("Preferences Repository Tests")
struct PreferencesRepositoryTests {

    @Test("Persistent container creation")
    func testPersistentContainerCreation() async throws {
        let schema = Schema([
            UserPreferencesModel.self,
            WeatherSnapshotModel.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [config])
        #expect(container != nil)
    }

    @Test("Default profile is returned when no data exists")
    func testDefaultProfile() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferencesModel.self, configurations: config)
        let context = ModelContext(container)

        let repository = SwiftDataPreferencesRepository(modelContext: context)

        let profile = try await repository.loadProfile()

        #expect(profile.language == .english)
    }

    @Test("Profile can be saved and loaded")
    func testSaveAndLoadProfile() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferencesModel.self, configurations: config)
        let context = ModelContext(container)

        let repository = SwiftDataPreferencesRepository(modelContext: context)

        var profile = UserComfortProfile.default
        profile.language = .english
        profile.appearance = .light
        profile.accentPalette = .ember
        profile.maximumDailyNotifications = 3
        profile.usualWorkoutTime = DateComponents(hour: 18, minute: 15)
        let istanbul = SavedLocation(
            id: "istanbul",
            name: "Istanbul",
            latitude: 41.0082,
            longitude: 28.9784,
            address: "Istanbul, Turkey",
            isFavorite: true
        )
        profile.savedLocations = [.currentLocation, istanbul]
        profile.selectedLocationID = istanbul.id
        profile.notificationPreferences = [
            NotificationPreference(category: .morningBriefing, isEnabled: false, preferredTime: DateComponents(hour: 8)),
            NotificationPreference(category: .weatherAlert, isEnabled: true, preferredTime: nil),
            NotificationPreference(category: .weatherAlert, isEnabled: true, preferredTime: nil)
        ]

        try await repository.saveProfile(profile)

        let loaded = try await repository.loadProfile()

        #expect(loaded.language == .english)
        #expect(loaded.appearance == .light)
        #expect(loaded.accentPalette == .ember)
        #expect(loaded.maximumDailyNotifications == 3)
        #expect(loaded.usualWorkoutTime?.hour == 18)
        #expect(loaded.savedLocations.contains(istanbul))
        #expect(loaded.selectedLocationID == istanbul.id)
        #expect(loaded.notificationPreferences.first { $0.category == .morningBriefing }?.isEnabled == false)
    }

    @Test("Onboarding completion status can be set and retrieved")
    func testOnboardingCompletion() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferencesModel.self, configurations: config)
        let context = ModelContext(container)

        let repository = SwiftDataPreferencesRepository(modelContext: context)

        let initialStatus = try await repository.isOnboardingCompleted()
        #expect(initialStatus == false)

        try await repository.setOnboardingCompleted(true)

        let updatedStatus = try await repository.isOnboardingCompleted()
        #expect(updatedStatus == true)
    }

    @Test("Profile updates existing record instead of creating new")
    func testProfileUpdate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserPreferencesModel.self, configurations: config)
        let context = ModelContext(container)

        let repository = SwiftDataPreferencesRepository(modelContext: context)

        let profile1 = UserComfortProfile.default
        try await repository.saveProfile(profile1)

        let profile2 = profile1
        try await repository.saveProfile(profile2)

        let loaded = try await repository.loadProfile()

        #expect(loaded.language == profile2.language)
    }
}
