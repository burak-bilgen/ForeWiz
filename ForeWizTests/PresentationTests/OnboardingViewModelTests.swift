import Foundation
import Testing
@testable import ForeWiz

@MainActor
@Suite("OnboardingViewModel Tests", .serialized)
struct OnboardingViewModelTests {

    @Test("initial language is english")
    func initialLanguageIsEnglish() async throws {
        L10n.configure(language: .english)
        let mockLocation = MockLocationRepository()
        let mockNotification = MockNotificationRepository()
        let viewModel = OnboardingViewModel(
            locationRepository: mockLocation,
            notificationRepository: mockNotification
        )

        #expect(viewModel.selectedLanguage == .english)
    }

    @Test("initial location status is notDetermined")
    func initialLocationStatusIsNotDetermined() async throws {
        L10n.configure(language: .english)
        let mockLocation = MockLocationRepository()
        let mockNotification = MockNotificationRepository()
        let viewModel = OnboardingViewModel(
            locationRepository: mockLocation,
            notificationRepository: mockNotification
        )

        #expect(viewModel.locationStatus == .notDetermined)
    }

    @Test("initial notification status is notDetermined")
    func initialNotificationStatusIsNotDetermined() async throws {
        L10n.configure(language: .english)
        let mockLocation = MockLocationRepository()
        let mockNotification = MockNotificationRepository()
        let viewModel = OnboardingViewModel(
            locationRepository: mockLocation,
            notificationRepository: mockNotification
        )

        #expect(viewModel.notificationStatus == .notDetermined)
    }

    @Test("canContinue is false when location not authorized")
    func canContinueIsFalseWhenLocationNotAuthorized() async throws {
        L10n.configure(language: .english)
        let mockLocation = MockLocationRepository()
        let mockNotification = MockNotificationRepository()
        let viewModel = OnboardingViewModel(
            locationRepository: mockLocation,
            notificationRepository: mockNotification
        )

        #expect(viewModel.canContinue == false)
    }

    @Test("selectLanguage changes language")
    func selectLanguageChangesLanguage() async throws {
        L10n.configure(language: .english)
        let mockLocation = MockLocationRepository()
        let mockNotification = MockNotificationRepository()
        let viewModel = OnboardingViewModel(
            locationRepository: mockLocation,
            notificationRepository: mockNotification
        )

        viewModel.selectLanguage(.turkish)

        #expect(viewModel.selectedLanguage == .turkish)
    }

    @Test("setErrorMessage updates error message")
    func setErrorMessageUpdatesErrorMessage() async throws {
        L10n.configure(language: .english)
        let mockLocation = MockLocationRepository()
        let mockNotification = MockNotificationRepository()
        let viewModel = OnboardingViewModel(
            locationRepository: mockLocation,
            notificationRepository: mockNotification
        )

        viewModel.setErrorMessage("Test error")

        #expect(viewModel.errorMessage == "Test error")
    }

    @Test("setErrorMessage nil clears error message")
    func setErrorMessageNilClearsErrorMessage() async throws {
        L10n.configure(language: .english)
        let mockLocation = MockLocationRepository()
        let mockNotification = MockNotificationRepository()
        let viewModel = OnboardingViewModel(
            locationRepository: mockLocation,
            notificationRepository: mockNotification
        )

        viewModel.setErrorMessage("Test error")
        viewModel.setErrorMessage(nil)

        #expect(viewModel.errorMessage == nil)
    }

    @Test("makeProfile sets language")
    func makeProfileSetsLanguage() async throws {
        L10n.configure(language: .english)
        let mockLocation = MockLocationRepository()
        let mockNotification = MockNotificationRepository()
        let viewModel = OnboardingViewModel(
            locationRepository: mockLocation,
            notificationRepository: mockNotification
        )

        viewModel.selectLanguage(.turkish)
        let profile = viewModel.makeProfile()

        #expect(profile.language == .turkish)
    }

    @Test("canContinue is true when location is denied but manual city is added")
    func canContinueIsTrueWhenLocationDeniedButManualCityAdded() async throws {
        L10n.configure(language: .english)
        let mockLocation = MockLocationRepository()
        let mockNotification = MockNotificationRepository()
        let viewModel = OnboardingViewModel(
            locationRepository: mockLocation,
            notificationRepository: mockNotification
        )

        #expect(viewModel.canContinue == false)

        let location = SavedLocation(
            name: "Istanbul",
            latitude: 41.0082,
            longitude: 28.9784,
            address: "Istanbul, Turkey"
        )
        viewModel.addManualLocation(location)

        #expect(viewModel.canContinue == true)
        #expect(viewModel.profile.selectedLocationID == location.id)
        #expect(viewModel.profile.savedLocations.contains(where: { $0.id == location.id }))
    }
}

final class MockNotificationRepository: NotificationRepository {
    func authorizationStatus() async -> NotificationAuthorizationStatus {
        .notDetermined
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        .notDetermined
    }

    func schedule(_ plans: [NotificationPlan]) async throws {
    }

    func cancelPendingSmartNotifications() async {
    }
}
