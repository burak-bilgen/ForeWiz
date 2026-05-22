# ForeWiz — App Store Policies & Compliance Guide

> **Purpose:** This document serves as the reference for App Store submission requirements.
> When submitting to App Store Connect, copy the relevant sections into the appropriate fields.

---

## 📜 Privacy Policy

**For App Store Connect → App Privacy → Privacy Policy URL**
Host this document on your website (e.g., `https://bilgenworks.com/forewiz/privacy`) or use a
privacy policy generator service.

---

### ForeWiz Privacy Policy

**Last updated:** May 21, 2026

#### 1. Data Collection & Usage

ForeWiz is designed with **privacy by default**. The app collects the minimum data necessary
to provide weather-adaptive decision recommendations.

| Data Type | Collected | Purpose | Third-Party Sharing |
|-----------|-----------|---------|-------------------|
| **Location** | Yes (foreground only) | To fetch local weather data from Apple WeatherKit | Never |
| **Preferences** | Yes | App settings (language, accent color, notification prefs, saved locations) — stored on-device only | Never |
| **Usage Data / Analytics** | **No** | ForeWiz does **not** include any analytics SDK, telemetry, or tracking code | N/A |
| **Advertising ID (IDFA)** | Yes (with consent) | Used by Google AdMob for personalized ad delivery | Google (via AdMob SDK) |
| **Crash Reports** | **No** | No crash reporting SDK is integrated | N/A |
| **Diagnostics** | **No** | No diagnostic data collection | N/A |

#### 2. Advertising & Consent

ForeWiz uses **Google AdMob** for monetization. The following applies:

- **ATT (App Tracking Transparency):** On iOS 14.5+, the app displays the ATT consent dialog
  on first launch. Ad personalization is only enabled if the user explicitly grants tracking permission.
- **GDPR Consent:** For users in the European Economic Area (EEA), ForeWiz uses
  Google's UMP (User Messaging Platform) SDK to obtain GDPR consent before loading any ads.
- **Ad Formats:** Banner, native inline, interstitial (app-open), and optional rewarded video ads.
- **Non-Personalized Ads:** If consent is denied, ForeWiz serves non-personalized ads only.

#### 3. Data Storage & Security

- **Location Data:** Used ephemerally to request weather data. Not stored, not logged.
- **Preferences:** All user preferences are stored **on-device** using Apple's SwiftData framework.
  No preference data is transmitted off-device.
- **Weather Data:** Cached locally with 15-minute TTL. Not shared.
- **Network Connections:** The app connects only to:
  - Apple WeatherKit (weather data)
  - Google AdMob (ad delivery, with user consent)
  - Apple MapKit (map tiles for WizPath route planning)

#### 4. Children's Privacy

ForeWiz does not knowingly collect data from children under 13. The app is not directed
at children and does not offer content targeted at minors.

#### 5. Data Deletion

Since all user data is stored on-device:
- **Uninstalling the app** removes all locally stored data.
- There is no server-side data to delete.
- Ad-related identifiers (IDFA) can be reset via iOS Settings → Privacy → Tracking.

#### 6. Contact

For privacy questions: [your-email@example.com]

---

## 🛡️ App Store Privacy Details (Checklist)

**For App Store Connect → App Privacy → Data Types**

Use this checklist when filling out the App Store Connect privacy questionnaire:

### Data Collected & Linked to User

| Data Type | Collected? | Used For | Linked to User? |
|-----------|-----------|----------|----------------|
| **Name** | ❌ No | — | — |
| **Email** | ❌ No | — | — |
| **Phone Number** | ❌ No | — | — |
| **Physical Address** | ❌ No | — | — |
| **Precise Location** | ✅ Yes | App Functionality | No |
| **Coarse Location** | ✅ Yes | App Functionality | No |
| **Health / Fitness** | ❌ No | — | — |
| **Payment Info** | ❌ No | — | — |
| **Contact Info** | ❌ No | — | — |
| **User Content** | ❌ No | — | — |
| **Search History** | ❌ No | — | — |
| **Browsing History** | ❌ No | — | — |
| **Device ID** | ✅ Yes (IDFA) | Third-Party Advertising | Yes (AdMob) |
| **Purchase History** | ❌ No | — | — |
| **Usage Data** | ❌ No | — | — |
| **Crash Data** | ❌ No | — | — |
| **Performance Data** | ❌ No | — | — |
| **Diagnostics** | ❌ No | — | — |

### Data Not Linked to User

| Data Type | Collected? | Purpose |
|-----------|-----------|---------|
| **Precise Location** | ✅ Yes | Local weather display (not stored, not shared) |
| **Coarse Location** | ✅ Yes | Local weather display (not stored, not shared) |

---

## ✅ App Review Submission Checklist

### 1.0 — Required Items

| Item | Status | Notes |
|------|--------|-------|
| Valid Apple Developer account ($99/year) | ✅ | — |
| App ID with correct bundle identifier | ✅ | — |
| App Store Connect record created | ⬜ | Must create before submission |
| App icon (all required sizes) | ✅ | Included in Assets.xcassets |
| Screenshots (6.7" + 5.5" + iPad) | ⬜ | See Section 3 below |
| App preview video (optional) | ⬜ | Recommended for decision engine demo |
| Privacy policy URL | ✅ | Host the document from Section 1 |
| Age rating | ⬜ | See Section 2.3 |
| Export compliance (ITSAppUsesNonExemptEncryption) | ⬜ | Set to NO (AdMob uses HTTPS only) |
| Content rights (if any third-party content) | ✅ | Weather data from Apple, maps from Apple |

### 2.0 — Technical Requirements

#### 2.1 Capabilities & Entitlements

| Capability | Required | Status |
|-----------|----------|--------|
| WeatherKit | Yes | ✅ Added |
| MapKit | Yes | ✅ Added |
| Push Notifications | Yes (for weather alerts) | ✅ |
| Background Modes | Yes (weather refresh) | ✅ |
| App Groups (Widgets) | Yes | ✅ |
| Sign in with Apple | No | ⬜ Optional |
| iCloud | No | Not needed |
| Wallet | No | Not needed |

#### 2.2 Info.plist Keys

| Key | Value | Status |
|-----|-------|--------|
| `NSLocationWhenInUseUsageDescription` | "ForeWiz uses your location to fetch local weather data." | ✅ |
| `NSUserTrackingUsageDescription` | "We show personalized ads with your permission. Data is shared with AdMob." | ✅ |
| `CFBundleDisplayName` | ForeWiz | ✅ |
| `BGTaskSchedulerPermittedIdentifiers` | Background weather refresh | ✅ |

#### 2.3 App Store Age Rating

Based on AdMob's content policies and the app's content:

| Category | Rating |
|----------|--------|
| **Frequency/Intensity of Cartoon or Fantasy Violence** | None |
| **Realistic Violence** | None |
| **Prolonged Graphic/Sadistic Realistic Violence** | None |
| **Profanity or Crude Humor** | None |
| **Mature/Suggestive Themes** | None |
| **Horror/Fear Themes** | None |
| **Medical/Treatment Information** | Infrequent/Mild (health-weather correlation) |
| **Alcohol, Tobacco, or Drug Use** | None |
| **Gambling** | None |
| **Simulated Gambling** | None |
| **Sexual Content or Nudity** | None |
| **Unrestricted Web Access** | No |
| **Contests** | No |
| **Unrestricted Web Access** | No |

**Recommended Age Rating:** **4+** (with no restricted categories)

### 3.0 — Screenshot Requirements

| Device | Size | Orientation | Count |
|--------|------|-------------|-------|
| iPhone 6.7" (iPhone 15 Pro Max) | 1290 × 2796 px | Portrait | 3–5 |
| iPhone 6.5" (iPhone 15 Pro) | 1242 × 2688 px | Portrait | 3–5 |
| iPhone 5.5" (iPhone 8 Plus) | 1242 × 2208 px | Portrait | 3–5 |
| iPad Pro (12.9") — optional | 2048 × 2732 px | Portrait | 3–5 |

**Recommended Screens:**

1. **Home Screen** — Hero card with outdoor score + weather data (proves value proposition)
2. **Weather Briefing** — Narrative + health analysis + comparative data (shows AI depth)
3. **WizPath Map** — Route with weather overlays (shows unique feature)
4. **WizPath Dashboard** — Journey HUD with departure optimizer (shows planning capability)
5. **Widgets** — Lock screen + home screen widgets (shows ecosystem integration)

---

## 🔐 App Store Connect Export Compliance

In App Store Connect → App Information → Export Compliance:

| Question | Answer | Reason |
|----------|--------|--------|
| Does your app use encryption? | **No** | AdMob uses standard HTTPS; no custom encryption |
| Does your app qualify for exemption? | Yes | Category 5, Note 3 — apps using only HTTPS qualify |
| Has your app been authorized for encryption? | N/A | No encryption used |

**Set `ITSAppUsesNonExemptEncryption` to `NO`** in Info.plist.

---

## 📝 Metadata for App Store Connect

### App Name
**ForeWiz** — Weather Decision Assistant

### Subtitle
Smarter than weather. Good for decisions.

### Description
**First paragraph (most important — shown without "more"):**

> ForeWiz doesn't just tell you the weather. It tells you what to do about it.
>
> Powered by Apple WeatherKit, ForeWiz analyzes temperature, humidity, UV, wind, and precipitation to produce a personalized outdoor score (0–100), the best time for your activities, what to wear, and how the weather might affect your health — all in one beautiful, ad-supported app.

**Subsequent paragraphs:**

> **🧠 Smart Decision Engine** — Our 7 specialized engines analyze every weather parameter to give you a clear outdoor score, optimal activity windows, and outfit recommendations tailored to your local forecast.
>
> **🏥 Health-Weather Tracking** — See how today's weather might affect your migraines, sleep quality, joint pain, respiratory comfort, and stamina. ForeWiz correlates 6+ weather factors with 5 health dimensions for a complete wellness picture.
>
> **🗺️ WizPath Route Planning** — Plan your journey with climate-aware routing. See weather conditions at every segment, get departure time optimization, and receive sentinel alerts when weather + traffic makes a route risky.
>
> **🌍 Fully Localized** — English and Turkish with formal tone. Dynamic language switching at runtime. Accessibility optimized with VoiceOver and Dynamic Type support.
>
> **💚 Privacy First** — Zero analytics, zero telemetry. All preferences stored on-device. Location used only for weather — never tracked, never shared.

### Keywords
`weather, forecast, outdoor, decision, planner, commute, health, migraine, pollen, UV, score, recommendation, activity, running, cycling, walking, trip, route, climate, WizPath, localization, Turkish`

### Support URL
`https://bilgenworks.com/forewiz/support`

### Marketing URL (optional)
`https://bilgenworks.com/forewiz`

---

## ⚠️ Common App Store Rejection Risks

| Risk | Mitigation | Status |
|------|-----------|--------|
| **4. 0 — Design: No placeholder content** | All sections show real weather data or clear loading/error states | ✅ |
| **2.1 — App Completeness** | No crash on launch, all features functional | ✅ |
| **2.3.10 — No hidden features** | No debug menus, no undocumented APIs | ✅ |
| **3.1.1 — In-App Purchase (if added)** | N/A — ForeWiz is ad-supported, no IAP currently | N/A |
| **3.2.1 — Acceptable (AdMob)** | Ad content is appropriate for 4+ rating, non-intrusive placement | ✅ |
| **5.1.1 — Location Privacy** | Location permission explained, used only when foreground | ✅ |
| **5.1.2 — Data Collection Consent** | ATT dialog shown on first launch for IDFA | ✅ |

---

## 📄 Export Compliance Documentation

No export compliance documentation is needed because:
- ForeWiz does not implement custom encryption
- All network communication uses standard HTTPS/TLS
- Apple's automatic encryption exemption applies (CAT5NOTE3)

---

*Keep this document updated as new features are added. Review before each App Store submission.*
