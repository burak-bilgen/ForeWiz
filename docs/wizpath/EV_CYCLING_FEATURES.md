# EV & Cycling Feature Plan for WizPath

> **Status:** Planning  
> **Target:** WizPathKit v4.0  

---

## 1. Electric Vehicle (EV) Features

### Current State
- `WizPathClimateService.getEVRecommendations()` — basic heat-based battery efficiency warnings
- `EVRecommendation` model with icon, title, description
- `POICategory.evCharger` — map POI type for charging stations (not yet displayed)

### Proposed Features

#### 1.1 Range Prediction Engine
**File:** `Packages/WizPathKit/Sources/WizPathKit/Services/EvRangeService.swift`

| Factor | Impact | Data Source |
|--------|--------|-------------|
| Temperature | Battery efficiency drops ~20% at -10°C, ~15% at 40°C | Weather segments on route |
| Wind (headwind) | Reduces range by ~10-15% at 30 km/h wind | Can be derived from weather data |
| Precipitation | Wet roads increase rolling resistance +5-10% | Weather condition per segment |
| Elevation gain | Climbing consumes ~2x energy per km | MapKit elevation data |
| Road type (highway vs city) | Highway less efficient for EVs | Transport type per route leg |

**New types:**
```swift
public struct EvRangeEstimate: Sendable {
    public let baseRangeKm: Double        // EPA-rated range
    public let adjustedRangeKm: Double    // Weather-adjusted
    public let consumptionWhPerKm: Double
    public let segments: [EvSegmentRange]
    public let recommendedChargeLevel: Double  // % needed
    public let estimatedChargeStops: Int
}

public struct EvSegmentRange: Sendable {
    public let segmentIndex: Int
    public let rangeConsumption: Double   // km of range consumed
    public let energyUsedKwh: Double
    public let factors: [EvRangeFactor]
}

public enum EvRangeFactor: Sendable {
    case temperature(degrees: Double, penalty: Double)
    case wind(speed: Double, direction: WindDirection, penalty: Double)
    case precipitation(type: WeatherCondition, penalty: Double)
    case elevationGain(meters: Double, penalty: Double)
    case roadType(type: RoadType, penalty: Double)
}
```

#### 1.2 Smart Charging Stop Planner
**File:** `Packages/WizPathKit/Sources/WizPathKit/Services/EvChargingPlannerService.swift`

Given a route and the EV's range + current charge, recommend optimal charging stops:

```swift
public struct EvChargingPlan: Sendable {
    public let stops: [ChargingStop]
    public let totalChargingTime: TimeInterval
    public let totalCost: Double
    public let routeImpact: RouteImpact  // time added vs non-stop
}

public struct ChargingStop: Sendable {
    public let chargerPOI: WizPathPOI
    public let arrivalChargePercent: Double
    public let recommendedChargePercent: Double
    public let estimatedChargeTime: TimeInterval
    public let estimatedCost: Double
    public let recommendation: String
}
```

**Algorithm:**
1. Simulate driving from origin to destination
2. Track battery % at each segment
3. When battery drops below threshold (15%), find nearest charger POI
4. Score chargers by: distance from route, charging speed, amenities, weather at location
5. Recommend optimal charging duration (enough to reach next charger or destination)

#### 1.3 Elevation-Aware Energy Model
**File:** `Packages/WizPathKit/Sources/WizPathKit/Services/EvElevationModel.swift`

- Fetch elevation data from MapKit's `MKElevation` API per route segment
- Calculate gradient (rise/run) for each segment
- Apply energy consumption multiplier:
  - Uphill 5%+ → 2.5x consumption
  - Uphill 2-5% → 1.5x consumption
  - Downhill → regenerative braking recovers ~60-70%
- Show elevation profile in route info panel

#### 1.4 Preconditioning Recommendation
- Already partially done via `getEVRecommendations()`
- Extend with:
  - **Smart timing:** Recommend preconditioning X minutes before departure based on battery temp vs ambient
  - **Plugin reminder:** If temp < 0°C or > 35°C and departure is within 2 hours, remind user to keep plugged in
  - **Departure timer:** Suggest setting a departure timer in the car's app for optimal battery temp

#### 1.5 UI Components for EV
**File:** `Packages/WizPathKit/Sources/WizPathKit/Views/Components/EvRangeIndicator.swift`

New UI components:
- **EvRangeIndicator:** Battery-style gauge showing current range vs required range, with weather-adjusted range
- **EvChargingStopCard:** Card showing each recommended charging stop with estimated time, cost, nearby amenities
- **EvBatteryTimeline:** Timeline view showing battery % at each major waypoint
- **EvPreconditionCard:** Card showing preconditioning recommendation with countdown

---

## 2. Cycling Features

### Current State
- `TravelMode` enum does not have a `.cycling` case
- No cycling-specific routing, weather, or health logic

### Proposed Features

#### 2.1 New Travel Mode: `.cycling`
**File:** `Packages/WizPathKit/Sources/WizPathKit/Domain/TravelMode.swift`

```swift
extension TravelMode {
    case cycling
    
    var localizedTitle: String { /* "Bicycle" / "Bisiklet" */ }
    var icon: String { "bicycle" }
    var transportType: MKDirectionsTransportType { /* .walking — Apple Maps doesn't have cycling routing on all regions, use walking as fallback */ }
    var averageSpeed: Double { 15.0 }  // km/h
    var weatherMultiplier: Double { 1.8 }  // cycling is more weather-sensitive
}
```

**Note:** Apple Maps `MKDirections` doesn't support `.cycling` directly. Strategy:
1. Try `.walking` transport type (which often uses cycle-friendly paths)
2. For regions where cycling directions are available (via `MKMapItem`), use polyline hints
3. Future: integrate with **cycle.travel** or **OSRM cycling** profile API

#### 2.2 Wind Sensitivity Analysis
**File:** `Packages/WizPathKit/Sources/WizPathKit/Services/CyclingWindService.swift`

Cyclists are heavily affected by wind. New service:

```swift
public struct CyclingWindAnalysis: Sendable {
    public let segments: [WindSegment]
    public let overallHeadwind: Double     // average headwind speed
    public let crosswindWarnings: [WindWarning]
    public let optimalDirection: TravelDirection?
}

public struct WindSegment: Sendable {
    public let segmentIndex: Int
    public let windSpeed: Double
    public let windDirection: WindDirection
    public let travelDirection: TravelDirection
    public let effectiveHeadwind: Double       // headwind component
    public let effortMultiplier: Double         // 1.0 = normal, 1.3 = heavy headwind
    public let isDangerous: Bool                // crosswind > 40 km/h
}

public struct WindWarning: Sendable {
    public let segmentIndex: Int
    public let type: CyclingWindWarningType  // .crosswind, .gust, .headwind
    public let message: String
    public let severity: RiskLevel
}
```

**Algorithm for headwind calculation:**
```
effectiveHeadwind = windSpeed × cos(windAngle - travelAngle)
// 0° = pure headwind → cos(0) = 1.0 → max penalty
// 90° = crosswind → cos(90) = 0 → no speed penalty, but stability risk
// 180° = tailwind → cos(180) = -1 → speed bonus
```

#### 2.3 Cycling Health & Safety Engine
**File:** `Packages/WizPathKit/Sources/WizPathKit/Services/CyclingSafetyService.swift`

```swift
public struct CyclingSafetyAssessment: Sendable {
    public let overallRisk: RouteRisk
    public let factors: [CyclingRiskFactor]
    public let recommendations: [CyclingRecommendation]
}

public enum CyclingRiskFactor: Sendable {
    case crosswind(speed: Double)
    case heavyRain
    case heatExhaustion(temperature: Double)
    case poorAirQuality(aqi: Int)
    case lowVisibility(fog: Bool, rain: Bool)
    case slipperyRoad(ice: Bool, wet: Bool, leaves: Bool)
    case darkness(isNight: Bool)
}

public enum CyclingRecommendation: Sendable {
    case avoidTimeWindow(start: Date, end: Date, reason: String)
    case takeAlternativeRoute(reason: String)
    case gearAdvice(gear: [String])
    case healthPrecaution(tip: String)
}
```

**Health factors specific to cycling:**
- **Dehydration:** Much higher sweat rate while cycling → water bottle reminder every 30 min in heat
- **Sun exposure:** Cycling at speed increases wind chill but UV exposure is higher
- **Air quality:** Cyclists breathe 2-3x more air than pedestrians → AQI matters more
- **Heat stroke:** Body heat generation from cycling + ambient temp = effective temp +5-10°C
- **Hypothermia risk:** Descending wet hills at low temps → wind chill can be dangerous

#### 2.4 Cycling Route Adaptation
**File:** `Packages/WizPathKit/Sources/WizPathKit/Services/CyclingRouteAdapter.swift`

Adapt the standard route for cycling:

```swift
public struct CyclingRouteAdaptation: Sendable {
    public let originalRoute: WizPathRoute
    public let adaptedRoute: WizPathRoute
    public let avoidanceZones: [AvoidZone]
    public let suggestedAlternatives: [WizPathRoute]
}

public struct AvoidZone: Sendable {
    public let coordinate: CLLocationCoordinate2D
    public let radius: CLLocationDistance
    public let reason: AvoidReason  // .steepHill, .highTraffic, .noBikeLane, .construction
}
```

**Adaptation logic for cycling:**
- Prefer roads with bike lanes / low traffic
- Avoid steep gradients (>8%) — suggest walking bike uphill or alternate route
- Break route into shorter segments (cyclists plan in 15-30 min chunks)
- Prioritize scenic routes / park paths over direct highways

#### 2.5 E-Bike Specific Features
- Display range based on battery assist level
- Suggest eco-mode on climbs for battery conservation
- Note: e-bikes have different speed profiles (~25-32 km/h with assist)
- Register battery range similar to EV features

#### 2.6 UI Components for Cycling
**File:** `Packages/WizPathKit/Sources/WizPathKit/Views/Components/CyclingSafetyCard.swift`

New UI components:
- **CyclingSafetyCard:** Shows wind, heat, and road condition warnings
- **WindDirectionArrow:** Animated compass showing wind direction vs travel direction
- **EffortProfileView:** Elevation + wind combined effort profile for the route
- **CyclingGearAdviceView:** Clothing/g ear recommendations based on weather
- **BikeLaneIndicator:** Shows % of route with dedicated bike infrastructure

---

## 3. Shared Infrastructure

### 3.1 Elevation Service (used by both EV and Cycling)
**File:** `Packages/WizPathKit/Sources/WizPathKit/Services/ElevationService.swift`

```swift
public final class ElevationService {
    public func fetchElevationProfile(for route: WizPathRoute) async throws -> ElevationProfile
    
    public func calculateTotalClimb(profile: ElevationProfile) -> Double
    public func calculateMaxGradient(profile: ElevationProfile) -> Double
    public func classifyTerrain(totalClimb: Double, distanceKm: Double) -> TerrainType
}

public enum TerrainType: Sendable {
    case flat          // < 50m per 10km
    case rolling       // 50-200m per 10km
    case hilly         // 200-500m per 10km
    case mountainous   // > 500m per 10km
}
```

### 3.2 Air Quality Service
**File:** `Packages/WizPathKit/Sources/WizPathKit/Services/AirQualityService.swift`

- Fetch AQI data from weather repository or Apple WeatherKit
- Used by cycling safety engine and walking health recommendations
- Display AQI color indicator on route

---

## 4. Implementation Roadmap

| Phase | Features | Estimated Effort |
|-------|----------|------------------|
| **Phase 1** (v4.0) | `TravelMode.cycling` + wind analysis + basic EV range | 2-3 weeks |
| **Phase 2** (v4.1) | EV charging planner + elevation service | 2-3 weeks |
| **Phase 3** (v4.2) | Cycling safety engine + UI components | 2 weeks |
| **Phase 4** (v4.3) | E-bike support + air quality | 1 week |

**Priority order for first implementation:**
1. `TravelMode.cycling` case — unlocks all cycling features
2. `CyclingWindService` — biggest impact for cyclists
3. `EvRangeService` — temperature + elevation aware range
4. New UI components for both modes

---

## 5. Localization Keys Needed

### EV Keys
| Key | EN | TR |
|-----|----|----|
| `ev_range_estimate` | Range Estimate | Menzi̇l Tahmini̇ |
| `ev_charge_stops` | Charging Stops | Şarj Durakları |
| `ev_precondition` | Precondition Cabin | Kabini Ön Koşullandır |
| `ev_battery_temp` | Battery Temperature | Batarya Sıcaklığı |
| `ev_elevation_impact` | Elevation Impact | Yokuş Etkisi |
| `ev_rec_charge_before` | Charge before departure | Çıkmadan şarj et |
| `ev_kwh_used` | kWh Used | kWh Tüketi̇len |
| `ev_cost_estimate` | Estimated Cost | Tahmini̇ Mali̇yet |

### Cycling Keys
| Key | EN | TR |
|-----|----|----|
| `cycling_wind_warning` | Strong Wind Warning | Kuvvetli Rüzgar Uyarısı |
| `cycling_crosswind` | Crosswind Risk | Yan Rüzgar Riski |
| `cycling_headwind` | Headwind Ahead | Ön Rüzgar |
| `cycling_effort_profile` | Effort Profile | Efor Profili |
| `cycling_terrain` | Terrain Type | Arazi Tipi |
| `cycling_bike_lane_pct` | Bike Lane Coverage | Bisiklet Yolu Oranı |
| `cycling_steep_climb` | Steep Climb | Dik Yokuş |
| `cycling_hydration_reminder` | Hydration Reminder | Su İçme Hatırlatması |
| `cycling_sun_protection` | Sun Protection | Güneş Koruması |
| `cycling_gear_advice` | Gear Advice | Giysi Önerisi |
| `cycling_ebike_range` | E-Bike Range | E-Bisiklet Menzili |

---

## 6. Test Plan

### Unit Tests Needed
| Test File | Coverage |
|-----------|----------|
| `CyclingWindServiceTests.swift` | Headwind calculation, crosswind detection, effort multiplier |
| `EvRangeServiceTests.swift` | Temperature penalty, elevation penalty, combined factors |
| `EvChargingPlannerTests.swift` | Charging stop placement, battery simulation |
| `CyclingSafetyServiceTests.swift` | Risk factor detection, recommendation generation |
| `ElevationServiceTests.swift` | Total climb calculation, gradient classification |

### Integration Tests
| Test | Scenario |
|------|----------|
| Route with cycling mode | Calculate route, verify wind analysis, verify safety warnings |
| Hot weather EV route | Verify range reduction, verify charging stop recommendations |
| Hilly cycling route | Verify effort profile, verify steep climb warnings |
| Crosswind scenario | Verify crosswind warning triggers at 40+ km/h |
