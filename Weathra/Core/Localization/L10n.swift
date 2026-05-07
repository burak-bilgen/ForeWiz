import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        String(localized: String.LocalizationValue(stringLiteral: key))
    }
}

enum L10nKey: String {
    case homeTitle
    case homeDailySummary
    case homeCurrentLocation
    case homeLastSaved
    case homeLive
    case homeLoading
    case homeErrorRetry
    case homeUpdated

    case weatherLiveForecast
    case weatherLatestForecast
    case weatherFeelsLike
    case weatherCurrent
    case weatherClear
    case weatherCloudy
    case weatherRainy
    case weatherSnowy
    case weatherStormy
    case weatherFoggy
    case weatherDataProvidedBy

    case decisionGood
    case decisionModerate
    case decisionRisky
    case decisionAvoid

    case widgetOutdoorScore
    case widgetBestTime

    case forecast3Day
    case forecast7Day
    case forecastNoBestWindow
    case forecastPremiumRequired

    case onboardingWelcome
    case onboardingSubtitle
    case onboardingWhyWeathra
    case onboardingWhySubtitle
    case onboardingSetupTitle
    case onboardingSetupSubtitle
    case onboardingContinue
    case onboardingReady
    case onboardingLocationRequired
    case onboardingFeatureDecision
    case onboardingFeatureDecisionDesc
    case onboardingFeaturePersonal
    case onboardingFeaturePersonalDesc
    case onboardingFeatureNotifications
    case onboardingFeatureNotificationsDesc

    case settingsHeaderTitle
    case settingsHeaderSubtitle
    case settingsAppearanceTitle
    case settingsAppearanceSubtitle
    case settingsComfortTitle
    case settingsComfortSubtitle
    case settingsNotificationsTitle
    case settingsNotificationsSubtitle
    case settingsPermissionsTitle
    case settingsPermissionsSubtitle
    case settingsPremiumTitle
    case settingsSavedLocationsTitle
    case settingsSavedLocationsSubtitle
    case settingsLanguageTitle
    case settingsLanguageSubtitle

    case tabToday
    case tabSettings

    case errorUnknown
    case errorLocationDenied
    case errorLocationUnavailable
    case errorWeatherUnavailable
    case errorNotificationDenied
    case errorCacheUnavailable

    case premiumTitle
    case premiumSubtitle
    case premiumUpgrade
    case premiumRestore
    case premiumRestoreSuccess
    case premiumRestoreNone

    case activityWalking
    case activityRunning
    case activityCycling
    case activityOutside

    case sensitivityNormal
    case sensitivityHot
    case sensitivityCold

    case riskLow
    case riskMedium
    case riskHigh
    case riskExtreme

    case aboutLegal
    case aboutLegalDesc
    case aboutAppleWeatherLegal
    case aboutDone

    case settingsCancel
    case settingsSave
}