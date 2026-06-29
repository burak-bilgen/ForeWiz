# ForeWiz — Personal Weather Decision Assistant

<p align="center">
  <img src="https://github.com/burak-bilgen/ForeWiz/blob/main/ForeWiz/Assets.xcassets/AppIcon.appiconset/256.png?raw=true" width="120" height="120" alt="ForeWiz">
</p>


<p align="center">
  <img src="https://img.shields.io/badge/iOS-17%2B-blue?style=flat-square&logo=apple" alt="iOS 17+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/Architecture-Clean%20%2B%20MVVM-blue?style=flat-square" alt="Architecture">
  <img src="https://img.shields.io/badge/SPM-WizPathKit-brightgreen?style=flat-square" alt="SPM">
  <img src="https://img.shields.io/badge/Localization-EN%20%2F%20TR-red?style=flat-square" alt="Localization">
  <img src="https://img.shields.io/badge/Tests-30%2B%20suites-success?style=flat-square" alt="Tests">
  <img src="https://img.shields.io/badge/SwiftUI-100%25-purple?style=flat-square" alt="SwiftUI">
</p>

ForeWiz transforms raw Apple WeatherKit data into **personalized, actionable decisions**. It analyzes current and forecasted conditions through a multi-engine decision pipeline to tell you not just what the weather *is*, but what it *means* for you — when to go out, what to wear, how your health may be affected, and which route is safest.

---

## Architecture

```
ForeWiz/
├── App/               # Entry point, coordinator, dependency injection
├── Core/              # Design system, localization, utilities
│   ├── DesignSystem/  # Theme, colors, animations, glass components
│   ├── Localization/  # L10n system (EN + TR)
│   ├── Location/      # Location service
│   └── Utilities/     # Logger, haptics, deep links, formatters
├── Data/              # Repository implementations
│   ├── Location/      # CoreLocation repository + mocks
│   ├── Notifications/ # UNNotification repository
│   ├── Persistence/   # SwiftData models
│   └── Weather/       # WeatherKit repository, mapper, cache
├── Domain/            # Business logic (pure Swift, Foundation only)
│   ├── Entities/      # Domain models
│   ├── Enums/         # Type definitions
│   ├── Repositories/  # Protocol interfaces
│   ├── Services/      # Decision engines, scoring, planners
│   └── UseCases/      # Business operations
├── Presentation/      # SwiftUI views + ViewModels
│   ├── Home/          # Main screen, briefing, HUD
│   ├── Insights/      # Weather insights
│   ├── Onboarding/    # Language + permissions setup
│   ├── Recommendations/
│   └── Shared/        # Reusable components
├── ForeWizWidgets/    # Widget extension
├── ForeWizLiveActivity/ # Live Activity extension
└── ForeWizTests/      # Unit tests (49 test files)
```

### Key Design Decisions

| Principle | Implementation |
|-----------|---------------|
| **Clean Architecture + MVVM-C** | Domain is pure Swift (Foundation only), Data handles I/O, Presentation owns SwiftUI |
| **Actor-based Concurrency** | Thread-safe services with Swift actors + async/await |
| **Protocol-driven Repositories** | Every data source has a protocol + mock + production implementation |
| **Deterministic Engines** | All decision engines are pure functions — fully unit testable |
| **Dependency Injection** | Centralized `DependencyContainer` with `.live()` and `.simulator()` factories |
| **Zero Force Unwraps** | All `!` unwraps eliminated in favor of `guard let` / `if let` / optional chaining |
| **250 LOC Ceiling** | Large files systematically refactored into focused, single-responsibility modules |

---

## Decision Engine Pipeline

ForeWiz processes weather data through a chain of specialized engines to produce holistic recommendations:

| Engine | Responsibility |
|--------|---------------|
| **ActivityWindowScoringEngine** | Scores each hour (0–100) based on temperature, precipitation, UV, wind, humidity |
| **OutfitDecisionEngine** | Recommends clothing combinations with natural-language advice |
| **WeatherDecisionEngine** | Computes overall outdoor score (0–100), identifies optimal time windows |
| **HealthWeatherService** | Analyzes impact on migraines, sleep, joints, respiratory health, stamina (5 calculators) |
| **WeatherNarrativeService** | Generates context-aware daily weather story with personality archetypes |
| **ComparativeWeatherService** | Compares today against seasonal norms, yesterday, and weekly trends |
| **WeatherBriefingService** | Combines narrative + health + comparative analysis into a single actionable briefing |
| **DefaultWeatherRiskClassifier** | Classifies 8 risk types: heat, UV, rain, wind, storm, humidity, cold, poor comfort |
| **NotificationPlanningEngine** | 5 planners: morning briefing, outfit, activity, smart risks, immediate risks |

### Health-Weather Correlation

| Factor | Inputs | Output |
|--------|--------|--------|
| **Migraine Risk** | Temperature swing, humidity, storms, UV | 0–10 risk score |
| **Sleep Quality** | Night temperature, humidity, wind, storms | 0–10 forecast |
| **Joint Pain** | Cold + humidity combo, sudden drops | 0–10 index |
| **Respiratory Comfort** | Cold air, humidity, wind + dry | 0–10 risk |
| **Stamina / Energy** | Heat index, humidity amplification, cold | 0–10 energy forecast |

---

## WizPath — Climate-Aware Route Planning

WizPath is a local SPM package that powers climate-aware route planning with weather intelligence at every segment:

- **Multi-modal routing** — Driving, cycling, walking, EV mode with battery efficiency warnings
- **Weather-coded polylines** — Green (good) to red (dangerous) per route segment
- **Cycling Safety Engine** — Crosswind risk, wet road analysis, effort level scoring
- **Departure Optimizer** — Analyzes 6-hour window, recommends optimal departure time
- **Route Comparison** — Scores multiple candidates with duration, traffic, weather severity analysis
- **Smart Stops** — POI search for gas, EV charging, rest stops with weather-at-arrival data
- **Journey HUD** — Real-time safety score, hazard list, next safe stop recommendation
- **Sentinel Alerts** — Push notifications when weather delays exceed thresholds
- **Live Activity** — Lock screen / Dynamic Island journey tracking

---

## Design System

A premium dark-mode aesthetic with liquid glass components and fluid animations:

- **LiquidGlassCard** — Ultra-thin material cards with animated diagonal sheen
- **LiquidOrbBackground** — Animated gradient orbs that change with weather conditions
- **Weather-responsive palettes** — Clear sky, stormy, snowy, rainy, night modes
- **Micro-interactions** — Haptic feedback, spring animations, staggered entrances
- **Scene transitions** — CardEntrance, StaggerEntrance, Float, PulseGlow
- **Enhanced Splash** — Weather-conditioned animated splash screen
- **Design tokens** — Centralized colors, typography, animation curves via WizPathKit

---

## Technical Highlights

- **Swift 6** with strict concurrency checking — actor-based thread safety
- **SwiftUI** — 100% declarative UI, no UIKit in production code
- **SwiftData** — On-device persistence with encryption for widget data
- **WidgetKit** — System small, medium, lock screen widgets
- **Live Activities** — Dynamic Island journey tracking
- **TipKit** — Contextual onboarding and feature discovery
- **Siri Shortcuts** — 6 custom intents (outdoor score, recommendations, health, outfit, etc.)
- **BGTaskScheduler** — Background refresh with smart cache invalidation
- **CI Pipeline** — GitHub Actions: lint, build all targets, run unit tests
- **Localization** — English + Turkish (formal tone) with runtime language switching

---

## Testing

| Suite | Coverage |
|-------|----------|
| WeatherDecisionEngineTests | Outdoor scoring, risk detection, window selection |
| OutfitDecisionEngineTests | Category selection, advice generation |
| ActivityWindowScoringEngineTests | Hourly scoring, edge cases |
| HealthWeatherServiceTests | All 5 calculators, overall scoring |
| NotificationPlanningEngineTests | Plan creation, deduplication, scheduling |
| WeatherBriefingServiceTests | Narrative integration, action items |
| DataConsistencyTests | Cache coherence, repository integration |
| LocalizationTests | Key coverage, format strings |
| ErrorHandlerTests | Error propagation, user messages |
| PerformanceTests | Scoring throughput, concurrency safety |

---

## Getting Started

### Requirements

- Xcode 16+
- iOS 17+ deployment target
- Apple Developer account with **WeatherKit** entitlement

### Setup

```bash
git clone https://github.com/bilgenworks/forewiz.git
cd forewiz
open ForeWiz.xcodeproj
```

1. Select the **ForeWiz** target
2. Signing & Capabilities → Add **WeatherKit**
3. Build and run (⌘R)

### Running Tests

```bash
xcodebuild test -project ForeWiz.xcodeproj -scheme ForeWiz \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

---

## Project Statistics

| Metric | Value |
|--------|-------|
| Swift files | ~200 (production) |
| Unit test files | 49 |
| Test suites | 30+ |
| Localized strings | ~1,000 keys (EN + TR) |
| External dependencies | Apple first-party + WizPathKit (local SPM) |
| Deployment target | iOS 17+ |
| Architecture layers | 4 (Domain, Data, Presentation, Core) |

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Built with Swift 6 + SwiftUI + WeatherKit + MapKit by <a href="https://github.com/bilgenworks">Bilgen Works</a></sub>
</p>
