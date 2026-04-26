# WeatherAssistant

WeatherAssistant is a personal weather decision assistant for iOS. The product goal is not to show a dense
forecast dashboard, but to answer practical daily questions in Turkish: what to wear, whether going outside
is sensible, which hours are best for running or walking, and which windows should be avoided.

## MVP Direction

- Onboarding for location, notifications, temperature sensitivity, preferred activities, and quiet hours.
- A calm home screen with one daily decision, outdoor score, best window, avoid hours, outfit guidance, and risks.
- A detail screen explaining hourly comfort, activity scoring, and the weather factors behind the recommendation.
- Settings for preferences, units, notification categories, and language-ready structure.
- Local smart notifications with a default cap of 2 per day and a hard cap of 3.

## Architecture

The app is structured around Clean Architecture with MVVM-C:

- `App`: entry point, app coordinator, environment, and dependency composition.
- `Core`: design system, localization helpers, date/logging/error utilities.
- `Domain`: entities, value objects, repository protocols, use-case protocols, and deterministic engines.
- `Data`: WeatherKit, CoreLocation, UserNotifications, SwiftData, mappers, and cache policy boundaries.
- `Presentation`: SwiftUI views, view models, coordinators, and reusable UI components.

Domain code imports Foundation only. WeatherKit, CoreLocation, SwiftData, UserNotifications, and SwiftUI types
must stay out of the domain layer.

## Current Slice

The current implementation slice includes:

- Project structure for the requested layers.
- Project, target, bundle, and source folder identity renamed to `WeatherAssistant`.
- Domain entities for weather snapshots, hourly/daily points, recommendations, risks, scores, profile, and notifications.
- Repository and use-case protocols.
- Deterministic decision engines for outdoor scoring, activity windows, outfit suggestions, and notification planning.
- A modern SwiftUI onboarding/home shell with adaptive glass-style components, score tiles, activity windows,
  outfit guidance, avoid hours, and risk chips.
- Swift Testing coverage for hot summer, mild spring, rain, wind, cold-sensitive users, and notification spam prevention.

## Weather Decision Engine

The MVP engine is deterministic and explainable. It starts from a comfort score of 100 and applies penalties for:

- apparent and actual temperature
- humidity
- wind
- precipitation chance and amount
- UV index
- severe weather risk
- daylight and time of day
- user temperature sensitivity

Outdoor decisions map score ranges as:

- `80...100`: good
- `60...79`: moderate
- `40...59`: risky
- `0...39`: avoid

Turkey summer rules are included for midday heat and UV windows.

## WeatherKit Setup Notes

WeatherKit must be enabled for the app identifier in the Apple Developer portal, and the target needs the
WeatherKit capability before the production repository is wired. The data layer will map WeatherKit framework
models into domain `WeatherSnapshot` values so framework types do not leak into presentation or domain code.

## Location

Location is used only to produce local weather recommendations for the user's current area. MVP does not require
continuous background location tracking. The user-facing permission copy is:

> Konumunu sadece bulunduğun yere uygun hava önerileri üretmek için kullanıyoruz.

## Notifications

The notification planner creates semantic `NotificationPlan` values. The repository layer schedules those plans
with UserNotifications. The planner deduplicates categories, respects quiet hours, keeps only the top 2 plans by
default, and never exceeds 3 daily plans.

## Caching

The cache policy is quota-aware:

- fresh if fetched within 20 minutes
- stale but usable up to 6 hours
- expired after that

The app should avoid WeatherKit calls on every view appearance. Refresh on launch only when stale, on explicit
pull-to-refresh, and after meaningful location or preference changes.

## SwiftData

SwiftData is reserved for user preferences, onboarding completion, notification settings, and latest weather cache.
Repositories are protocol-based so persistence can be replaced without touching the domain or presentation layers.

## SwiftLint

SwiftLint is configured in `.swiftlint.yml` with strict practical rules, including force unwrap prevention and
sorted imports. Preferred setup is Homebrew SwiftLint plus an Xcode build phase:

```sh
swiftlint
```

## Tests

Run unit tests with:

```sh
xcodebuild test -project WeatherAssistant.xcodeproj -scheme WeatherAssistant -destination 'platform=iOS Simulator,name=iPhone 17e,OS=26.4.1'
```

## Privacy

MVP stores preferences, onboarding state, notification choices, and cached weather locally on device. It does not
include third-party analytics, paid AI APIs, a remote backend, or background location tracking. Local notifications
are generated on device from weather recommendations.

## Roadmap

- Full WeatherKit repository and mappers.
- CoreLocation one-shot location repository.
- SwiftData-backed preferences and weather cache.
- Full onboarding flow and settings editing.
- Recommendation detail timeline.
- WidgetKit daily decision card.
- ActivityKit run/walk weather window.
- Apple Watch companion app.
- StoreKit subscriptions.
- Calendar, HealthKit, and wardrobe-aware suggestions.
