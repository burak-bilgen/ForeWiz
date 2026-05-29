# ForeWiz Privacy Policy

**Last updated:** May 22, 2026

## 1. Data Collection & Usage

ForeWiz is designed with **privacy by default**. The app collects the minimum data necessary to provide weather-adaptive decision recommendations.

| Data Type | Collected | Purpose | Third-Party Sharing |
|-----------|-----------|---------|-------------------|
| **Location** | Yes (foreground only) | To fetch local weather, route weather, maps, and nearby route places | Apple WeatherKit / MapKit |
| **Preferences** | Yes | App settings (language, accent color, notification prefs, saved locations) — stored on-device/app group only | Never |
| **Usage Data / Analytics** | Limited | Local app/ad performance events; no third-party analytics SDK | Not sold; AdMob receives ad interaction data for ad delivery |
| **Advertising ID (IDFA)** | Yes (with consent) | Used by Google AdMob for personalized ad delivery | Google (via AdMob SDK) |
| **Crash Reports** | **No** | No crash reporting SDK is integrated | N/A |
| **Diagnostics** | **No** | No diagnostic data collection | N/A |

## 2. Advertising & Consent

ForeWiz uses **Google AdMob** for monetization. The following applies:

- **ATT (App Tracking Transparency):** On iOS 14.5+, the app displays the ATT consent dialog on first launch. Ad personalization is only enabled if the user explicitly grants tracking permission.
- **GDPR Consent:** For users in the European Economic Area (EEA), ForeWiz uses Google's UMP (User Messaging Platform) SDK to obtain GDPR consent before loading any ads.
- **Ad Formats:** Banner, native inline, interstitial (app-open), and optional rewarded video ads.
- **Non-Personalized Ads:** If consent is denied, ForeWiz serves non-personalized ads only.

## 3. Data Storage & Security

- **Location Data:** Used ephemerally to request weather data. Not stored, not logged.
- **Preferences:** All user preferences are stored **on-device** using Apple's SwiftData framework. No preference data is transmitted off-device.
- **Weather Data:** Cached locally with 15-minute TTL. Not shared.
- **Network Connections:** The app connects only to:
  - Apple WeatherKit (weather data)
  - Google AdMob (ad delivery, with user consent)
  - Google UMP (ad consent forms/privacy options)
  - Apple MapKit (map tiles, route planning, local search for WizPath)

## 4. Children's Privacy

ForeWiz does not knowingly collect data from children under 13. The app is not directed at children and does not offer content targeted at minors.

## 5. Data Deletion

Since all user data is stored on-device:
- **Uninstalling the app** removes all locally stored data.
- There is no server-side data to delete.
- Ad-related identifiers (IDFA) can be reset via iOS Settings → Privacy → Tracking.

## 6. Contact

For privacy questions: **[support@forewiz.app](mailto:support@forewiz.app)**
