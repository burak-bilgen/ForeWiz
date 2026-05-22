# WizPath Architecture Blueprint

> **Son Güncelleme:** Mayıs 2026
> **Kapsam:** Multi-modal (Car / Walking / Cycling) route-based weather forecasting system

---

## Overview

WizPath, kullanıcının seçtiği güzergah boyunca hava durumu, iklim, trafik ve güvenlik faktörlerini birleştirerek akıllı rota önerileri sunar. Apple Maps (MapKit) üzerinden rota hesaplar, her segment için ETA bazlı hava durumu binding yapar.

---

## Core Architecture

### 1. Domain Layer (Models)

```
WizPathRoute
├── origin: CLLocationCoordinate2D
├── destination: CLLocationCoordinate2D
├── travelMode: TravelMode (car / walking / cycling)
├── departureTime: Date
├── segments: [WizPathSegment]
├── totalDuration: TimeInterval
├── totalDistance: CLLocationDistance
├── polyline: MKPolyline?
├── overallRisk: RouteRisk (good / caution / severe)
└── weatherChangePoints: [WizPathSegment]

WizPathSegment
├── coordinate: CLLocationCoordinate2D
├── estimatedArrival: Date
├── weather: SegmentWeather?
├── distanceFromStart: CLLocationDistance
├── travelTime: TimeInterval
└── etaDisplay: String

SegmentWeather
├── condition: SegmentWeatherCondition
├── temperature: Double
├── precipitationChance: Double
├── windSpeed: Double
├── visibility: Double?
└── severity: SegmentWeatherSeverity (good / fair / caution / severe)

TravelMode (enum)
├── .car           — icon: car.fill,        interval: 15dk, speed: 50km/s
├── .walking       — icon: figure.walk,     interval: 30dk, speed: 5km/s
└── .cycling       — icon: bicycle,         interval: 10dk, speed: 15km/s, windSensitive: true
```

### 2. Service Layer

```
WizPathService (Actor)
├── calculateRoute(origin, destination, mode, departureTime) -> WizPathRoute
│   └── MapKit MKDirections ile rota + segment interpolasyonu
├── interpolateSegments(route: MKRoute) -> [WizPathSegment]
├── fetchWeatherForSegments([WizPathSegment]) -> [SegmentWeather]
└── Recent Destinations (save/load/deduplicate)

WizPathCache (Singleton)
├── store(route:) / route(origin:destination:mode:) -> WizPathRoute?
├── TTL: 15 minutes
├── Entry grouping: (origin, destination, mode) → route
└── clear() -> void

DepartureOptimizerService
├── findOptimalDepartureTime(...) -> DepartureOptimizationResult
├── 12 × 30dk pencere, her biri weather + traffic + climate skoru
├── Scoring:
│   └── Car:     Weather 40% / Traffic 35% / Climate 25%
│   └── Walking: Weather 50% / Traffic 20% / Climate 30%
│   └── Cycling: Weather 50% / Traffic 20% / Climate 30%
│       └── + Midday heat penalty (11:00-15:00)
│       └── + Night cycling penalty (-25)
│       └── + Early morning bonus (05:00-08:00, +10)
└── Climate scoring: wind, temperature, precipitation factors

WizPathClimateService (Singleton, @MainActor)
├── analyzeRouteClimate(route, travelMode) -> ClimateAnalysis
├── applyClimateAdjustment(to:) -> ClimateAdjustedRoute
├── getHeatHealthRecommendations(temperature:travelMode:) -> [HealthRecommendation]
├── getCyclingSafetyRecommendations(windSpeed:temperature:precipitationChance:) -> [HealthRecommendation]
├── getEVRecommendations(temperature:) -> [EVRecommendation]
└── Climate Alerts: heatStroke, evBattery, infrastructureStress, roadClosure

WizPathCyclingSafetyService (Singleton, @MainActor) [YENİ]
├── analyzeCyclingSafety(route:) -> CyclingSafetyAnalysis
├── Crosswind detection: ≥25 km/h caution, ≥40 km/h dangerous
├── Headwind detection: ≥20 km/h significant, ≥45 km/h extreme
├── Effort level computation (1-10): wind + temperature + precipitation
├── Safety tiers: .safe / .caution(reason) / .notRecommended(reason)
└── CyclingWindSegment: segmentIndex, windSpeed, isHeadwind, eta

WizPathSentinelService (Singleton, @MainActor)
├── evaluateRouteChange(originalRoute:updatedRoute:weatherContext:) -> SentinelDecision
├── dispatchSentinelAlert(alert:) -> void
└── Saves lastRouteHash + detects significant route changes

WizPathWeatherService
├── Builds WizPathWeatherSnapshot from external weather API
├── Formats weather data into SegmentWeather
└── Maps condition codes to SegmentWeatherCondition
```

### 3. UI Layer

```
WizPathDashboardView (Root)
├── DestinationPicker (Map + Search)
├── DepartureTimePicker
├── TravelModeToggle [Car | Walking | Cycling]
├── WizPathMapView
│   ├── MKMapView with Route Overlay
│   ├── WeatherIconOverlay (color-coded by severity)
│   ├── ETAMarkerAnnotations
│   ├── DangerZoneHighlights
│   └── Weather Marker'lar (tıklanabilir → WeatherDetailSheet)
└── WizPathDetailView
    ├── SegmentCards
    ├── WeatherTimeline
    ├── Climate Alerts
    ├── CyclingSafetyPanel [YENİ - sadece cycling modunda]
    └── RiskSummary

WeatherDetailSheet [YENİ - lokalize edildi]
├── Hero header (condition icon + temperature + wind)
├── Details grid (ETA, Precipitation, Visibility, Severity)
├── Safety recommendation (hava durumuna göre)
└── Liquid glass card styling

CyclingSafetyPanel [YENİ]
├── Safety badge (Safe / Caution / Not Recommended)
├── Effort meter (1-10 scale, circular gauge)
├── Wind details (speed, gust, crosswind count)
├── Crosswind warnings
└── Safety recommendations

JourneyHUDView
├── Route status (optimal / warning / critical / noRoute)
├── ETA display
└── Live updates with auto-refresh
```

### 4. ViewModel Layer

```
WizPathViewModel (@MainActor, @Observable)
├── State: .idle / .calculating / .routeReady(WizPathRoute) / .error / .offline
├── Travel mode management + car/walking/cycling switching
├── Route calculation with MapKit + weather binding
├── Climate analysis integration
├── Cycling safety analysis (cyclingSafetyAnalysis + cyclingSafetyRecommendations)
├── Departure time optimization (6 saatlik pencere)
├── Sentinel route change detection
├── Auto-refresh (3 dk'da bir sessiz trafik güncellemesi)
├── Recent destinations (load/save/select)
└── Haptic feedback integration
```

### 5. Design System

| Element | Renk | Kullanım |
|---|---|---|
| Route Line (Good) | `#00FF41` Neon Green | Normal koşullar |
| Route Line (Caution) | `#FF9500` Orange | Dikkat gerektiren |
| Route Line (Severe) | `#FF3B30` Red | Tehlikeli |
| Background | AMOLED Black (#000) | Ana zemin |
| Cards | UltraThinMaterial + Glass morphism | Pencere kartları |
| Accent | Liquid Blue (#3F99FF) | Vurgu |
| Typography | SF Pro Rounded | Tüm metinler |

### 6. Data Flow

```
Kullanıcı Hedef Seçer
  → ViewModel.setDestination()
    → WizPathService.calculateRoute() (MapKit)
      → MKDirections request (transportType: car/walking/cycling)
      → Route + segment interpolation (every 10-30 min based on mode)
      → Weather fetch for each segment's ETA
      → WizPathBuilder combines route + weather
    → ClimateService.analyzeRouteClimate()
      → Heat/health/EV alerts
    → CyclingSafetyService.analyzeCyclingSafety() [if cycling]
      → Crosswind, headwind, effort level detection
    → ClimateService.getCyclingSafetyRecommendations() [if cycling]
      → Hydration, crosswind, wet roads warnings
    → SentinelService.evaluateRouteChange() [if recalculating]
    → DepartureOptimizerService.findOptimalDepartureTime()
      → 12 window scoring (weather + traffic + climate)
    → state = .routeReady(route)
      → UI updates (Map, Panel, HUD, CyclingSafetyPanel)
    → Auto-refresh timer starts (3 minutes)
      → Silent traffic recalculation (keeps old route on failure)
```

### 7. Performance Strategy

| Strateji | Detay |
|---|---|
| **API Throttling** | Batch weather requests: max 5 concurrent |
| **Segment Sampling** | 10-30 dk aralıklarla (mode'a göre) |
| **Cache TTL** | 15 dakika weather/route cache |
| **Departure Prefetch** | Tek weather fetch → 12 pencere yeniden kullanır |
| **Debounce** | Traffic updates: 30s minimum |
| **Auto-Refresh** | 3 dk'da bir, hata sessiz, alert yok |
| **Segment Limit** | Max 20 aktif segment |
| **Map Annotations** | Off-screen annotation unloading |

### 8. Error Handling

| Durum | Kullanıcıya Gösterilen |
|---|---|
| **Rota Bulunamadı** | "Route Blocked / System Error" |
| **Yürüme Yolu Yok** | "This route requires a vehicle" |
| **Weather API Hatası** | "Limited forecast available — check connection" |
| **Offline** | "No internet connection" |
| **Auto-Refresh Hatası** | Sessiz — eski rota korunur |
| **Destination Yok** | "Please select a destination" |

### 9. Test Coverage

```
WizPathServiceTests
├── Service initialization with DI
├── Recent destinations (save/load/limit/dedup)
├── Cache (store/retrieve/missing/clear)
├── Route risk calculation (good/caution/severe)
├── Weather change points detection
├── TravelMode segment intervals
└── Weather severity mapping

DepartureOptimizerServiceTests
├── Basic departure optimization
├── Multiple windows scoring
├── Cycling wind penalty scoring
├── Cycling day vs night scoring
└── Weather-aware scoring

WizPathCyclingSafetyServiceTests [YENİ]
├── Safe conditions → safe
├── Crosswind detection → caution/notRecommended
├── Effort level computation
├── Non-cycling mode guard
└── Extreme wind → notRecommended

WizPathViewModelTests [YENİ]
├── Initial state (idle, travelMode, destination)
├── Travel mode switching (car/walking/cycling)
├── Cycling analysis lifecycle
├── Destination setting
├── Computed properties
├── Reset behavior
├── Departure time clamping
└── Sentinel alerts initialization
```

### 10. Localization

- **Diller:** English (EN) + Turkish (TR)
- **Toplam Key Sayısı:** 12,000+ (ForeWiz ana app) + 80+ WizPath özel
- **WizPath Key Grupları:**
  - `wizpath_mode_*` — Seyahat modları (car/walking/cycling)
  - `wizpath_weather_*` — Hava durumu UI (ETA, precipitation, visibility, severity)
  - `wizpath_condition_*` — Hava durumu koşulları (clear, rain, snow, fog...)
  - `wizpath_severity_*` — Şiddet seviyeleri (good, fair, caution, severe)
  - `wizpath_rec_*` — Güvenlik önerileri (thunderstorm, fog, heat...)
  - `wizpath_cycling_*` — Bisiklet güvenliği (safety, effort, crosswind...)
  - `wizpath_*` — Genel WizPath UI (route_planner, destination, error...)
- **Yapı:** Apple .xcstrings formatı (JSON tabanlı)
- **Bridge:** `WizPathKitL10n` → `ForeWizL10nProvider` (WizPathKit → main app)
