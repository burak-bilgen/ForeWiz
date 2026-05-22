# 🌤️ ForeWiz - Personal Weather Decision Assistant

<p align="center">
  <img src="https://github.com/bilgenworks/forewiz/blob/main/ForeWiz/Assets.xcassets/AppIcon.appiconset/1024.png?raw=true" width="120" height="120" alt="ForeWiz">
</p>

<p align="center">
  <strong>Your smart weather sidekick. Not just weather - decisions.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17%2B-blue?style=flat-square&logo=apple" alt="iOS 17+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/Architecture-Clean%20%2B%20MVVM-blue?style=flat-square" alt="Architecture">
  <img src="https://img.shields.io/badge/Monetization-AdMob-purple?style=flat-square" alt="AdMob">
</p>

ForeWiz transforms raw Apple WeatherKit data into **personalized, actionable decisions**. It doesn't just tell you it's raining - it tells you *when* to go out, *what* to wear, *where* the weather is safest on your route, and *how* it might affect your health.

> Built with Apple's native frameworks + **Google AdMob** for sustainable monetization.

---

## ✨ Key Features

### 🧠 Decision Engine
ForeWiz processes weather data through a chain of specialized engines to produce holistic recommendations:

| Engine | What It Does |
|--------|-------------|
| **WeatherDecisionEngine** | Computes overall outdoor score (0–100), classifies into good/moderate/risky/avoid, identifies optimal time windows |
| **ActivityWindowScoringEngine** | Scores each hour (0–100) based on temperature, precipitation, UV, wind, humidity, and time-of-day bonuses |
| **OutfitDecisionEngine** | Recommends clothing combinations from 10+ categories with natural-language advice |
| **HealthWeatherService** | Analyzes impact on migraines, sleep, joints, respiratory health, and stamina - 5 independent calculators |
| **WeatherNarrativeService** | Generates a human-like "story" about today's weather with personality archetypes (energetic, melancholic, serene, dramatic, cozy, etc.) — now dynamically context-aware, referencing actual temperature, wind, humidity, and time of day |
| **ComparativeWeatherService** | Compares today against seasonal norms, yesterday, and weekly trends with anomaly detection |
| **WeatherBriefingService** | Combines narrative + health + comparative analysis into a single actionable daily briefing with prioritized action items |
| **DefaultWeatherRiskClassifier** | Classifies 8 risk types: heat, UV, rain, wind, storm, humidity, cold, poorComfort |

### 🌡️ Health-Weather Correlation
ForeWiz goes beyond basic weather by showing **how weather affects your body**:

| Factor | Inputs | Output |
|--------|--------|--------|
| **Migraine Risk** | Temperature swing, humidity, storms, UV | 0–10 risk score + explanation |
| **Sleep Quality** | Night temperature, humidity, wind, storms | 0–10 forecast + advice |
| **Joint Pain** | Cold+humidity combo, sudden drops | 0–10 index + tips |
| **Respiratory Comfort** | Cold air, humidity, wind+dry | 0–10 risk + recommendations |
| **Stamina/Energy** | Heat index, humidity amplification, cold | 0–10 energy forecast |

→ **Overall Health Score** (0–100) with a one-sentence summary.

### 🗺️ WizPath - Climate-Aware Route Planning
Plan your journey with **weather-aware routing**. WizPath calculates weather conditions at every segment of your route based on estimated arrival time:

- **Multi-modal**: Driving (15-min segments) or Walking (30-min segments)
- **Color-coded map**: Neon Green (good) → Orange (caution) → Red (dangerous)
- **Place Name Annotations**: Weather change points now show real location names (e.g. "Kadıköy", "Levent") via reverse geocoding, so you know exactly where conditions shift
- **Sentinel Alerts**: High-value notifications only when delays exceed 30 min or 40%
- **Extreme Heat Module**: EV battery warnings at 38°C+, pedestrian heat stroke alerts at 36°C+, climate multipliers for ETA
- **Departure Optimizer**: Finds the best time to leave based on weather + traffic
- **Journey HUD**: Real-time safety score, active hazards, next safe stop

### 🔔 Smart Notifications
Five notification planners work together to keep you informed without noise:

- **Morning Briefing** - Daily weather narrative + key action items
- **Outfit Plan** - Clothing recommendations for the day
- **Activity Plan** - Best outdoor windows based on comfort scores
- **Smart Risk Plans** - Severe weather alerts with interruption levels
- **Immediate Risk Plans** - Time-sensitive danger warnings

→ Deduplication, quiet hours, configurable daily limits.

### 🎨 Liquid Glass Design System
A premium dark-mode aesthetic with fluid animations:

- **LiquidOrbBackground** - Animated gradient orbs that change with weather conditions
- **GlassCard** - Ultra-thin material cards with neon accents
- **Micro-interactions** - Haptic feedback, spring animations, staggered entrances
- **Weather-responsive palettes** - Clear sky, stormy, snowy, rainy, night modes
- **Scene transitions** - CardEntrance, StaggerEntrance, Float, PulseGlow modifiers
- **Enhanced Splash** - Weather-conditioned animated splash screen

### 📱 Home Screen & Widgets

**Home Screen:**
- Real-time weather card with temperature, conditions, wind, humidity, UV
- Smart briefing section (narrative + health + comparative)
- WizPath HUD card for quick journey status
- Multi-location support with map-based search
- Language switcher and location picker in toolbar

**Widgets (WidgetKit):**
- **System Small** - Current conditions + outdoor score ring
- **System Medium** - Current conditions + 4-day forecast with score bars
- **Lock Screen Inline** - Temperature + condition text
- **Lock Screen Circular** - Outdoor score ring
- **Lock Screen Rectangular** - Detailed current conditions

### 🌍 Localization & Accessibility
- **English** and **Turkish** (fully translated via `.xcstrings`)
- **Formal Turkish tone** — all UI strings use formal "siz" (you) pronoun for corporate/professional voice
- **Turkish naturalness audit**: All 22 WizPath Turkish translations reviewed — 18 spelling fixes (Tipii→Tipi, rüzgar→rüzgâr with circumflex) + 4 naturalness improvements ("tespit edildi" → "var"/"bekleniyor", "enkaz" → "döküntü")
- Dynamic language switching at runtime
- Accessibility: dynamic type, reduce motion support, VoiceOver labels
- Biometric and haptic feedback for interactions

### 💰 Smart Ad Monetization
ForeWiz uses **Google AdMob** with intelligent ad placement that respects user experience:

| Ad Format | Placement | Strategy |
|-----------|-----------|----------|
| **Banner** | Native ad card + bottom home banner | Smart fatigue prevention, cooldown intervals |
| **Native** | Inline content ad card | Context-aware placement in forecast sections |
| **Interstitial** | Between navigation transitions | App-open ads (every N foregrounds) + session gating |
| **Rewarded** | Optional video ads for premium features | User-initiated, value-exchange model |

**Key Features:**
- **AdFatiguePrevention** - Adaptive frequency capping based on user engagement
- **AdRevenueTracker** - Per-unit revenue tracking with eCPM calculation
- **AdPlacementStrategy** - Session-based placement rules, app-open gating
- **AdConsentManager** - ATT (iOS 14.5+) and GDPR consent management
- **AdAnalyticsEngine** - Impression, click, and revenue analytics
- **Configurable daily limits & cooldowns** per ad unit

### 🧩 Siri Shortcuts (6 Intents)
- Get current outdoor score
- Get today's recommendation
- Check health-weather impact
- Get outfit suggestion
- Get activity windows
- Quick refresh

### 🚚 Background Refresh
- BGTaskScheduler for periodic weather updates
- Background notifications for severe weather changes
- Smart cache invalidation (15-min TTL, stale data detection)

---

## 🏗️ Architecture

```
ForeWiz/
├── App/               # Entry point, coordinator, dependency injection
├── Core/              # Design system, localization, utilities
│   ├── DesignSystem/  # Theme, colors, animations, glass components, ad views
│   ├── Localization/  # L10n system, xcstrings (EN + TR)
│   ├── Location/      # LocationService with hardened timeout
│   └── Utilities/     # Logger, haptics, deep links, AdMob integration, analytics
├── Data/              # Repository implementations
│   ├── Location/      # CoreLocation repository + mocks
│   ├── Notifications/ # UNNotification repository + content factory
│   ├── Persistence/   # SwiftData models (UserPreferences, WeatherSnapshot)
│   └── Weather/       # WeatherKit repository, mapper, cache policy
├── Domain/            # Business logic (pure Swift, Foundation only)
│   ├── Entities/      # Models: DailyRecommendation, WeatherScore, Narrative, etc.
│   ├── Enums/         # ActivityType, RiskLevel, OutdoorDecision, etc.
│   ├── Repositories/  # Protocol interfaces (Location, Weather, Preferences, etc.)
│   ├── Services/      # Decision engines, scoring, alerts, planners
│   └── UseCases/      # Business operations (LoadRecommendation, ScheduleNotifications, etc.)
├── Features/          # Feature modules
│   └── WizPath/       # Climate-aware route planning (map, dashboard, sentinel)
├── Presentation/      # SwiftUI views + ViewModels
│   ├── Home/          # Main screen, briefing, HUD card, ad placements
│   ├── Insights/      # Weather insights view
│   ├── Onboarding/    # Language + permissions setup (incl. ATT consent)
│   ├── Recommendations/ # Detailed recommendation view
│   └── Shared/        # Location picker, splash, root views, error screens
└── ForeWizWidgets/         # Widget extension (small, medium, lock screen)
    ├── WidgetProvider.swift
    ├── WidgetViews.swift
    ├── WidgetLocalization.swift
    └── WidgetEntry.swift
```

### Key Design Decisions

| Principle | Implementation |
|-----------|---------------|
| **Clean Architecture + MVVM-C** | Domain is pure Swift (Foundation only), Data handles I/O, Presentation owns SwiftUI |
| **AdMob Monetization** | Google AdMob with smart fatigue prevention, revenue tracking, consent management, and configurable placements |
| **Actor-based Concurrency** | Thread-safe services with Swift actors + async/await |
| **Protocol-driven Repositories** | Every data source has a protocol + mock + production implementation |
| **Deterministic Engines** | All decision engines are pure functions - fully unit testable |
| **Dependency Injection** | Centralized `DependencyContainer` with `.live()` and `.simulator()` factories |
| **Facade Refactoring** | Large files (>400 lines) split into focused, single-responsibility modules |

---

## 📦 Module Overview

<details>
<summary><b>Domain Layer - 50+ files</b></summary>

```
Services/
├── WeatherDecisionEngine.swift          # Core decision orchestrator
├── ActivityWindowScoringEngine.swift    # Hourly scoring (0-100)
├── OutfitDecisionEngine.swift           # 10+ clothing categories
├── HealthWeatherService.swift           # 5 health calculators
│   ├── HealthMigraineCalculator.swift
│   ├── HealthSleepCalculator.swift
│   ├── HealthJointCalculator.swift
│   ├── HealthRespiratoryCalculator.swift
│   └── HealthStaminaCalculator.swift
├── WeatherNarrativeService.swift        # Human-like story generation
├── WeatherBriefingService.swift         # Combines all analyses
├── ComparativeWeatherService.swift      # Normals, trends, anomalies
├── DefaultWeatherRiskClassifier.swift   # 8 risk types
├── NotificationPlanningEngine.swift     # 5 notification planners
│   ├── MorningBriefingPlanner.swift
│   ├── OutfitPlanBuilder.swift
│   ├── ActivityPlanBuilder.swift
│   ├── RiskPlanBuilder.swift
│   └── NotificationPlanHelpers.swift
├── RecommendationStore.swift            # Cached recommendations
├── RecommendationExplainer.swift        # Human-readable explanations
├── SevereWeatherAlertService.swift      # Critical alerts
├── FeatureGate.swift                    # Feature flags
└── DepartureOptimizerService.swift      # Optimal departure finder (WizPath)

Entities/
├── DailyRecommendation.swift
├── WeatherScore.swift
├── WeatherNarrative.swift
├── HealthWeatherAnalysis.swift
├── ComparativeWeatherAnalysis.swift
├── DailyWeatherBriefing.swift
├── OutfitRecommendation.swift
├── ActivityRecommendation.swift
├── UserComfortProfile.swift
├── TimeWindow.swift
├── WeatherSnapshot.swift
├── HourlyWeatherPoint.swift
├── DailyWeatherPoint.swift
├── SavedLocation.swift
└── NotificationPreference.swift

UseCases/
├── LoadHomeRecommendationUseCase.swift
├── UpdateUserPreferencesUseCase.swift
├── CompleteOnboardingUseCase.swift
└── ScheduleSmartNotificationsUseCase.swift
```
</details>

<details>
<summary><b>Presentation Layer - 20+ views</b></summary>

```
Home/
├── HomeView.swift                     # Main screen with toolbar + content + splash
├── HomeViewModel.swift                # State management
├── HomeViewState.swift                # Loadable state enum
├── HomeViewStateFactory.swift         # State construction
└── Components/
    ├── BriefingSection.swift          # Narrative + health + comparative UI
    └── WizPathHUDCard.swift           # Quick journey status

Onboarding/
├── OnboardingView.swift               # Language + permissions setup
└── OnboardingViewModel.swift

Recommendations/
├── RecommendationDetailView.swift
├── RecommendationDetailViewModel.swift
└── Components/
    ├── RecommendationWhyThisView.swift # Explanation UI
    └── HourlyRecommendationRow.swift

Shared/
├── AppRootView.swift                   # Navigation root
├── AppSplashView.swift                 # Animated launch
├── LocationPickerView.swift            # Map-based city search
├── ScreenErrorView.swift               # Error + retry
└── ShareSheet.swift
```
</details>

<details>
<summary><b>Core Design System - 15+ components</b></summary>

```
DesignSystem/
├── AppTheme.swift                      # Colors, typography, motion tokens
├── ThemeManager.swift                  # Dark mode manager
├── GlassCard.swift                     # Ultra-thin material cards
├── GlassButton.swift                   # Glass-styled buttons
├── ScoreRingView.swift                 # Animated score rings
├── OrbBackground.swift                 # LiquidOrb + AnimatedOrbBackground
├── EntranceAnimations.swift            # StaggerEntrance, CardEntrance, Float
├── ShimmerAndSheen.swift               # Shimmer + LiquidSheen modifiers
├── ButtonStyles.swift                  # PressScale, FullTapArea
├── PulseAndLoader.swift                # PulseGlow + PulsingDotsLoader
├── AnimationHelpers.swift              # Preview helpers
├── WeatherGradientService.swift        # Weather-responsive gradient orchestrator
├── WeatherGradientTypes.swift          # GradientSet + ParticleEffect types
├── WeatherGradientGenerator.swift      # Gradient computation
├── WeatherAwareBackground.swift        # Background view
├── WeatherStateTransitionManager.swift # Smooth transitions between weather states
├── MicroInteractionManager.swift       # Haptic + animation coordination
├── AdvancedAnimations.swift            # Reactive animations
└── EnhancedWeatherSplash.swift         # Weather-conditioned splash
```
</details>

---

## 🚀 Getting Started

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
3. Build and run (`⌘R`)

### Running Tests

```bash
xcodebuild test -project ForeWiz.xcodeproj -scheme ForeWiz \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Test domains:
- Decision engines (weather, outfit, activity window)
- Notification planning
- Localization coverage
- Error handling
- Data consistency
- Performance benchmarks

---

## 🔧 Build & CI

```bash
xcodebuild build -project ForeWiz.xcodeproj -scheme ForeWiz -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

**CI Pipeline (`.github/workflows/ci.yml`):**
1. SwiftLint linting (`--strict`)
2. Build all targets
3. Run unit tests
4. Localization completeness check

---

## 📊 Project Statistics

| Metric | Value |
|--------|-------|
| **Total Swift files** | ~140 |
| **Unit tests** | 25+ test suites |
| **Localized strings** | ~200 keys (EN + TR) — formal Turkish tone |
| **Build errors/warnings** | 0 error, 0 warning (production target) |
| **Force unwraps in production code** | **0** — fully eliminated |
| **External dependencies** | **Google AdMob + UMP** (monetization/consent) — everything else Apple-first-party |
| **Deployment target** | iOS 17+ |

### File Size Management
Large files systematically refactored into focused modules:

| Original File | Before | After | Reduction |
|---------------|--------|-------|-----------|
| `HomeView.swift` | 899 | ~150 | -749 |
| `WizPathDashboardView.swift` | 847 | ~150 | -697 |
| `EnhancedWeatherSplash.swift` | 712 | ~120 | -592 |
| `LocationPickerView.swift` | 702 | ~200 | -502 |
| `SiriShortcutsManager.swift` | 460 | 0 (deleted) | -460 |
| `HealthWeatherService.swift` | 440 | ~80 | -360 |
| `DefaultNotificationPlanningEngine.swift` | 420 | ~70 | -350 |
| `WeatherGradientService.swift` | 413 | ~50 | -363 |
| `AnimationHelpers.swift` | 424 | ~20 | -404 |
| **Total** | **~7,800** | **~1,700** | **-6,100** |

---

## 🔒 Privacy

- **Location**: Used for local weather, route weather, and MapKit search - no background tracking
- **Preferences**: Stored **on-device** via SwiftData/app group; widget payloads are encrypted locally
- **Analytics**: No third-party analytics SDK; only local app/ad performance counters
- **Network**: Apple WeatherKit/MapKit plus Google AdMob/UMP for ads and consent

---

## 🧪 Testing Strategy

| Test Suite | What It Covers |
|-----------|----------------|
| `WeatherDecisionEngineTests` | Outdoor scoring, risk detection, window selection |
| `OutfitDecisionEngineTests` | Category selection, advice generation |
| `ActivityWindowScoringEngineTests` | Hourly scoring, time bonuses, edge cases |
| `HealthWeatherServiceTests` | All 5 calculators, overall scoring |
| `NotificationPlanningEngineTests` | Plan creation, deduplication, scheduling |
| `WeatherBriefingServiceTests` | Narrative integration, action items |
| `DataConsistencyTests` | Cache coherence, repository integration |
| `LocalizationTests` | Key coverage, format strings |
| `ErrorHandlerTests` | Error propagation, user messages |
| `PerformanceTests` | Scoring throughput, concurrency safety |

---

## 📱 License

Private project. All rights reserved.

---

---

## 📋 Changelog

### v1.2.0 — Dynamic Narrative, Learning Feedback & WizPath Polish

| Change | Details |
|--------|---------|
| 🗺️ **Place Name Annotations** | WizPath map now shows real location names (e.g. "Kadıköy", "Levent") at weather change points via reverse geocoding with actor-based caching |
| 🧠 **Dynamic Narrative Engine** | WeatherNarrativeService now context-aware — generates stories referencing actual temperature, wind, humidity, and time-of-day instead of static templates. 16 new localization keys |
| 📝 **User Feedback System** | New WeatherFeedbackCard lets users rate forecasts (cold/good/hot). Feedback adjusts temperature offset and wind sensitivity for personalized future scores. 7 new localization keys |
| 🗣️ **Turkish Naturalness Audit** | 22 WizPath translations reviewed: 18 spelling fixes (Tipii→Tipi, rüzgar→rüzgâr) + 4 naturalness improvements (AI-sounding phrases → natural Turkish) |
| 🔒 **Swift 6 Concurrency Fixes** | GeocodingHelper rewritten with actor-based cache + sequential resolution to comply with strict concurrency |
| 📋 **App Store Policies** | Comprehensive Privacy Policy, App Review checklist, and submission guide added to docs/

---

### v1.1.0 — Code Quality & Localization Polish

| Change | Details |
|--------|---------|
| 🇹🇷 **Formal Turkish Tone** | All ~70 Turkish UI strings converted from informal "sen" to formal "siz" (corporate/professional voice). Includes decision messages, health advice, weather instructions, Siri responses, and WizPath strings |
| 🧹 **Build Error Fixes** | Resolved all compiler errors (2 errors + 9 warnings): OnboardingView memberwise init, ForeWizApp NSURL throws, AdComponents dangling reference, ModelConfiguration non-throwing init |
| ⚠️ **Warning Cleanup** | Fixed ~15 warnings: unused variables, deprecated `contentEdgeInsets`, unnecessary `try?`, Swift 6 concurrency capture semantics, double-backslash string interpolation |
| 🔒 **Force Unwrap Elimination** | Removed all 19 force unwraps across 6 files — replaced with `guard let` / `if let` / optional chaining. **Zero force unwraps in production code** |

---

<p align="center">
  <sub>Built with ☀️ + 🧊 by Bilgen Works</sub>
</p>
