# Weathra — Personal Weather Decision Assistant

<p align="center">
  <img src="Assets/AppIcon.png" width="120" height="120" alt="Weathra App Icon">
</p>

<p align="center">
  <strong>Weathra</strong> answers your daily weather questions before you even ask them.
</p>

<p align="center">
  <a href="https://apps.apple.com/app/weathra"><img src="https://img.shields.io/badge/App%20Store-Weathra-blue?style=flat-square&logo=apple" alt="App Store"></a>
  <a href="https://twitter.com/weathraapp"><img src="https://img.shields.io/badge/Twitter-WeathraApp-1DA1F2?style=flat-square&logo=twitter" alt="Twitter"></a>
  <img src="https://img.shields.io/badge/iOS-17%2B-green?style=flat-square&logo=apple" alt="iOS 17+">
  <img src="https://img.shields.io/badge/Swift-6-orange?style=flat-square&logo=swift" alt="Swift 6">
</p>

---

## What is Weathra?

Weathra is an intelligent weather companion that goes beyond forecasts. It understands *your* comfort preferences, activities, and sensitivities to deliver personalized outdoor decisions.

**No dashboards. No clutter. Just answers.**

- "Should I go for a run today?"
- "What should I wear?"
- "When's the best time to be outside?"
- "Are there any weather risks I should know about?"

Weathra answers all of these — automatically, every morning.

---

## Key Features

### Decision-First Weather
Weathra doesn't just show you temperature and precipitation. It synthesizes every weather factor into a single **outdoor score (0-100)** and clear decision: **Great, go outside** / **Be careful** / **Stay in**.

### Personalized Comfort Engine
Every person feels temperature differently. During onboarding, Weathra learns:
- Your temperature sensitivity (cold, normal, hot)
- Your preferred outdoor activities (running, walking, cycling)
- Health sensitivities (pollen, air quality, smoke, dust)

Your profile shapes every recommendation, score, and notification.

### Smart Timing
Weathra identifies your **best activity windows** based on your schedule. No more guessing — it tells you exactly when conditions are ideal for your workout.

### Outfit Intelligence
Based on temperature, wind, precipitation chance, and UV, Weathra recommends specific clothing and accessories. "Wear layers — cold front arriving at noon."

### Wind-Aware Decisions
Strong winds affect cycling, running, and general comfort. Weathra factors in wind speed and direction for more accurate outdoor scores.

### Risk Alerts
Get notified about:
- **Heat waves** and cold snaps
- **High UV** and sunburn risk
- **Rain** and storm windows
- **Wind** hazards for outdoor activities
- **Air quality** concerns
- **Pollen** peaks based on your sensitivities

### Bilingual Experience
Full support for **English** and **Turkish**. Weathra adapts to your preferred language seamlessly.

### Beautiful Dark UI
Designed with a modern glassmorphic aesthetic. Deep gradients, adaptive backgrounds that change with weather conditions, smooth animations throughout.

---

## Screenshots

| Home Screen | Risk Alerts | Insights |
|-------------|-------------|----------|
| ![Home](.github/screenshots/home.png) | ![Risks](.github/screenshots/risks.png) | ![Insights](.github/screenshots/insights.png) |

---

## Architecture

Weathra is built with **Clean Architecture** and **MVVM-C** pattern:

```
Weathra/
├── App/                 # App entry point, coordinator, dependency injection
├── Core/                # Design system, localization, utilities
├── Data/                 # WeatherKit, CoreLocation, SwiftData, StoreKit
├── Domain/               # Business logic, entities, use cases, engines
└── Presentation/         # SwiftUI views, view models, coordinators
```

**Key architectural principles:**
- Domain layer imports Foundation only — no UI or framework dependencies
- WeatherKit integration for accurate Apple Weather data
- Deterministic decision engines with full test coverage
- Protocol-based repositories for persistence flexibility

---

## Technology Stack

| Category | Technology |
|----------|------------|
| **Framework** | SwiftUI |
| **Language** | Swift 6.2 |
| **Min iOS** | iOS 17.0 |
| **Weather Data** | Apple WeatherKit |
| **Location** | CoreLocation |
| **Persistence** | SwiftData |
| **Monetization** | StoreKit 2 (Subscriptions) |
| **Ads** | Google AdMob |
| **Architecture** | Clean Architecture + MVVM-C |
| **Testing** | Swift Testing |
| **Linting** | SwiftLint |

---

## Monetization Model

### Free Tier
Everything you need to get started:

- Daily outdoor decision with score
- Best activity window
- 3-day forecast
- Risk alerts
- Outfit recommendations
- Basic notification scheduling
- Banner ads

### Premium Tier ($4.99/month or $29.99/year)
For users who want the complete experience:

| Feature | Free | Premium |
|---------|------|---------|
| Outdoor Score & Decision | Yes | Yes |
| Best Activity Window | Yes | Yes |
| 3-Day Forecast | Yes | **14-Day Forecast** |
| Risk Alerts | Yes | Yes |
| Outfit Suggestions | Yes | Yes |
| Wind Analysis | Yes | Yes |
| Basic Insights | Limited | **Full Analytics** |
| **Remove Ads** | No | **Yes** |
| Notification Priority | Normal | **Time Sensitive** |

### Subscription Details
- **Monthly**: $4.99/month
- **Yearly**: $29.99/year (save 50%)
- Subscriptions auto-renew unless cancelled 24 hours before period end
- Manage subscriptions in iOS Settings > Account > Subscriptions

---

## Ad Strategy

Weathra respects your experience. Free users see a single, non-intrusive banner ad at the bottom of the home screen. Premium subscribers enjoy a completely ad-free experience.

**Ad formats:**
- Single standard banner (320x50) on free tier
- No interstitials, no video ads, no pop-ups

---

## Privacy & Data

**Weathra keeps your data on your device.**

- Location is used **only** for local weather — no background tracking
- Preferences and weather cache stored locally via SwiftData
- No third-party analytics
- No AI cloud APIs
- No data sold or shared

> "Konumunu sadece bulunduğun yere uygun hava önerileri üretmek için kullanıyoruz."

---

## Getting Started

### Prerequisites
- Xcode 16+
- iOS 17+ Simulator or device
- Apple Developer account with WeatherKit capability enabled

### Setup
```bash
# Clone the repository
git clone https://github.com/bilgenworks/weathra.git
cd weathra

# Install dependencies
pod install

# Open in Xcode
open Weathra.xcworkspace
```

### WeatherKit Configuration
1. Enable WeatherKit in [Apple Developer Portal](https://developer.apple.com)
2. Add WeatherKit capability to your App ID
3. Create a key with WeatherKit service

---

## Roadmap

- [ ] **WidgetKit** daily decision widget
- [ ] **ActivityKit** Live Activities for outdoor windows
- [ ] **Apple Watch** companion app
- [ ] **Siri Shortcuts** integration
- [ ] **HealthKit** activity correlation
- [ ] **Calendar** event-aware recommendations
- [ ] **Wardrobe** integration for smarter outfit suggestions

---

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## License

Copyright © 2026 Bilgen Works. All rights reserved.

---

## Contact

- **Website**: [weathra.app](https://weathra.app)
- **Twitter**: [@weathraapp](https://twitter.com/weathraapp)
- **Email**: hello@weathra.app

---

<p align="center">
  <sub>Made with ☁️ + 🧠 by <a href="https://bilgenworks.com">Bilgen Works</a></sub>
</p>