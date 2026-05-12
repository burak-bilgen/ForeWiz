# ForeWiz — Personal Weather Decision Assistant

<p align="center">
  <img src="Assets/AppIcon.png" width="120" height="120" alt="ForeWiz">
</p>

<p align="center">
  <strong>Your weather sidekick. Smart outfit suggestions, activity timing, and AI-powered recommendations.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-26%2B-green?style=flat-square&logo=apple" alt="iOS 26+">
  <img src="https://img.shields.io/badge/Swift-6.3-orange?style=flat-square&logo=swift" alt="Swift 6.3">
  <img src="https://img.shields.io/badge/Architecture-Clean%20%2B%20MVVM-blue?style=flat-square" alt="Architecture">
</p>

---

## Features

### ☀️ Smart Home Screen
Real-time weather card with animated gradient backgrounds, temperature, conditions, wind, humidity, UV, and sunrise/sunset — all in a beautiful glassmorphic design.

### 🤖 AI Outfit Suggestions
Tap "AI Outfit Tip" on the home screen to get intelligent clothing recommendations based on current weather conditions. Powered by `NaturalLanguage` NLP processing with smart fallback.

### 📈 Temperature Trend Chart
Interactive bezier curve chart showing hourly comfort scores for the next 12 hours. See how the day progresses at a glance.

### 🔔 Smart Notifications
Severe weather alerts, best time recommendations, and daily summaries — all configurable. Background refresh keeps data current.

### 📍 Multi-Location Support
Save and switch between multiple cities. Beautiful map-based search with `MapKit` integration. Swipe-to-delete, hero current-location card.

### 🎨 Dynamic Design System
Fluid animated backgrounds that change color based on weather conditions (sunny, rainy, cloudy, stormy, snowy). Glassmorphism cards, spring animations, reduce-motion support.

### 🗣️ Localization
Fully localized in **English** and **Turkish**. Easy to extend with additional languages.

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| **UI** | SwiftUI with custom design system |
| **Weather** | Apple WeatherKit |
| **Location** | CoreLocation + MapKit |
| **Persistence** | SwiftData |
| **Notifications** | UserNotifications (UNUserNotificationCenter) |
| **Background** | BGTaskScheduler |
| **NLP** | NaturalLanguage (NLTagger) |
| **Haptics** | CoreHaptics (UIFeedbackGenerator) |
| **Architecture** | Clean Architecture + MVVM-C |
| **Concurrency** | Swift actors, async/await |
| **Widget** | WidgetKit (system small/medium, lock screen) |

---

## Architecture

```
ForeWiz/
├── App/               # App entry, coordinator, DI container
├── Core/              # Design system, localization, utilities
│   ├── DesignSystem/  # Theme, colors, typography, animations
│   ├── Localization/  # L10n system, xcstrings
│   └── Utilities/     # Logging, haptics, performance, AI service
├── Data/              # WeatherKit, CoreLocation, SwiftData
│   ├── Location/      # CoreLocation repository + mocks
│   ├── Notifications/ # UNNotification repository
│   ├── Persistence/   # SwiftData models
│   └── Weather/       # WeatherKit integration, mapper, cache
├── Domain/            # Business logic, entities, engines
│   ├── Entities/      # Models (Article, Weather, Recommendation)
│   ├── Enums/         # ActivityType, WeatherScore, etc.
│   ├── Repositories/  # Protocol interfaces
│   ├── Services/      # Decision engines, scoring, alerts
│   └── UseCases/      # Business operations
├── Presentation/      # SwiftUI views + ViewModels
│   ├── Home/          # Main weather screen, trend chart
│   ├── Insights/      # Weather insights and analytics
│   ├── Onboarding/    # First-launch experience
│   ├── Recommendations/ # Detailed recommendations
│   ├── Settings/      # Preferences, notifications
│   └── Shared/        # Location picker, root views
└── ForeWizWidget/     # Widget extension
```

### Key Design Decisions

- **Zero third-party dependencies** — no CocoaPods, SPM, or Carthage
- **Domain layer imports Foundation only** — clean separation of concerns
- **Actor-based concurrency** — thread-safe data access
- **Protocol-driven repositories** — mockable, testable data layer
- **Deterministic decision engines** — fully unit tested
- **IntelligenceService** — Apple Intelligence ready with graceful fallback

---

## Getting Started

### Requirements
- Xcode 26+
- iOS 26+ deployment target
- Apple Developer account with WeatherKit entitlement

### Setup
```bash
git clone https://github.com/bilgenworks/forewiz.git
cd forewiz
open ForeWiz.xcodeproj
```

Enable WeatherKit capability in Xcode: Target → Signing & Capabilities → + → WeatherKit.

---

## Testing

```bash
xcodebuild test -project ForeWiz.xcodeproj -scheme ForeWiz -destination 'platform=iOS Simulator,name=iPhone 16'
```

The project includes unit tests for:
- Decision engines (weather, outfit, activity window)
- Notification planning
- Localization coverage
- Error handling
- Data consistency

---

## Build & CI

```bash
xcodebuild build -project ForeWiz.xcodeproj -scheme ForeWiz -destination 'generic/platform=iOS'
```

CI pipeline (`.github/workflows/ci.yml`):
- Lint with SwiftLint
- Build all targets
- Run unit tests
- Verify localization

---

## Privacy

- **Location is used only for local weather** — no background tracking
- **All preferences stored on-device** via SwiftData
- **No analytics, no telemetry, no third-party SDKs**
- **No data leaves your device**

---

<p align="center">
  <sub>Built with ☀️ + 🧊 by <a href="https://bilgenworks.com">Bilgen Works</a></sub>
</p>
