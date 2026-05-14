# WizPath v3.0 - "Climate-Aware Predictive Engine"

## Overview
Advanced predictive engine optimized for metropolitan gridlock and extreme climate conditions (Global Warming / Heatwaves). Provides high-value, proactive advice while minimizing notification noise.

## 🆕 v3.0 Features

### 1. High-Value "Sentinel" Notifications (Noise Reduction)

**Threshold Logic:**
```swift
// ONLY fire notification if:
- Predicted delay > 30 minutes
- OR total travel time increases by > 40%

// Additional safeguards:
- Max 3 notifications/hour
- 15-minute cooldown between similar alerts
- Severity-based interruption levels
```

**Sentinel Decision Tree:**
```
Route Update Detected
    ↓
Time Difference > 30 min OR > 40% increase?
    ├─ NO → Suppress (below threshold)
    ↓ YES
Rate Limit Check (max 3/hour)?
    ├─ EXCEEDED → Suppress (rate limited)
    ↓ OK
Cooldown Check (15 min since last similar)?
    ├─ ACTIVE → Suppress (cooldown)
    ↓ READY
Calculate Severity (Critical/High/Medium/Low)
    ↓
Build Weather-Specific Alert
    ↓
Dispatch with UNNotificationRequest
```

**Severity Levels:**
- **Critical**: >2h delay OR >100% increase OR blizzard/extreme heat
- **High**: >60 min OR >70% increase OR severe conditions
- **Medium**: >30 min OR >40% increase (baseline)
- **Low**: Below thresholds but noteworthy

### 2. Extreme Heat & Climate Integration (Global Warming Module)

**Temperature Thresholds:**
| Condition | Threshold | Impact |
|-----------|-----------|--------|
| EV Battery Alert | 38°C (100°F) | Reduced efficiency warning |
| Pedestrian Heat Risk | 36°C (97°F) | Heat stroke warning |
| Extreme Heat | 40°C (104°F) | 1.25x ETA + vehicle stress |
| Critical Heat | 45°C (113°F) | Maximum warnings |

**Climate Multipliers:**
```swift
Snow/Blizzard:     2.2x  (Maximum priority)
Heavy Rain:        1.6x
Severe Storm:      1.4x
Extreme Heat:      1.25x (>40°C) + Vehicle Stress
High Heat:         1.15x (35-40°C)
Moderate Heat:     1.05x (32-35°C)
```

**EV-Specific Warnings (38°C+):**
- Pre-cool cabin while plugged in
- Reduced battery efficiency due to cooling requirements
- Extended charging time recommendations

**Pedestrian Health Warnings (36°C+):**
- Heat stroke risk alerts
- 15-minute shade break recommendations
- 500ml+ water carry suggestions
- Frequent hydration reminders

### 3. Climate-Aware Timeline UI

**Visual Heat Representation:**
```
Temperature    Color        Visual Effect
────────────────────────────────────────────
<32°C         #00FF41      Optimal - solid green
32-36°C       #FFCC00      Moderate - yellow bar
36-40°C       #FF9500      High heat - orange + heat haze
≥40°C         #FF3B30      Extreme - red + sun flare
```

**Heat Visualization Effects:**
1. **Heat Haze**: Wavy distortion animation (36°C+)
   - 3 animated wave layers
   - Orange tint overlay
   - Speed varies by intensity

2. **Sun Flare**: Radiating glow effect (40°C+)
   - Central radial gradient
   - 8 radiating rays
   - Pulsing intensity animation

3. **Score Reduction**: Dynamic quality score
   - 40°C+: Score × 0.6 (60% reduction)
   - 36°C+: Score × 0.8 (20% reduction)

**Terminal Output:**
```
> CLIMATE_WARNING: Extreme Heat (42°C) detected at Destination. ETA adjusted.
> CLIMATE_NOTICE: High heat (38°C) may affect travel comfort.
> TRAFFIC_WARNING: Metropolitan gridlock detected. +45min to ETA.
> ROUTE_OPTIMAL: Conditions favorable for departure at 08:00.
```

### 4. Sentinel Notification Formatter

**Weather-Specific Alert Titles:**
| Weather | Title Format |
|-----------|-------------|
| Extreme Heat (42°C) | 🌡️ EXTREME HEAT: +45 min Added |
| Heavy Snow | ❄️ HEAVY SNOW: +30 min to Journey |
| Blizzard | 🌨️ BLIZZARD WARNING: +1h Critical Delay |
| Severe Storm | ⛈️ SEVERE STORM: +25 min Delay Expected |
| Gridlock | 🚗 METROPOLITAN GRIDLOCK: +40 min |
| Flooding | 🌊 FLOODING ALERT: +35 min Route Impact |
| High Winds | 💨 HIGH WINDS: +20 min Safety Delay |

**Notification Body Structure:**
```
ETA changed from 2h 15m to 3h 00m
🌡️ Extreme heat (42°C) reducing efficiency
🔋 EV battery cooling required
⚠️ Heat stroke risk - frequent shade stops recommended

💡 Pre-cool cabin while plugged in to save battery

🛡️ Sentinel Alert - High-value notification
```

**iOS Interruption Levels:**
- **Critical**: Critical heat/blizzard - immediate attention
- **TimeSensitive**: Severe conditions - break through Focus
- **Active**: Moderate delays - standard notification
- **Passive**: Low priority - silent delivery

## 🏗️ Architecture

### New Services

**WizPathSentinelService.swift**
```swift
func evaluateRouteChange(original, updated) -> SentinelDecision
func dispatchSentinelAlert(alert) async

Thresholds:
- minimumDelayMinutes: 30
- minimumPercentageIncrease: 0.40
- maxNotificationsPerHour: 3
- cooldownMinutes: 15
```

**WizPathClimateService.swift**
```swift
func analyzeRouteClimate(route, mode) -> ClimateAnalysis
func applyClimateAdjustment(route, analysis) -> ClimateAdjustedRoute
func getHeatHealthRecommendations(temp, mode) -> [HealthRecommendation]
func getEVRecommendations(temp) -> [EVRecommendation]
```

**DepartureOptimizerService.swift**
```swift
func findOptimalDepartures(route, mode) -> DepartureOptimizationResult
func identifySentinelSlots(slots) -> [SentinelSlotAlert]

Multiplier Matrix:
- snowBlizzard: 2.2
- heavyRain: 1.6
- severeStorm: 1.4
- extremeHeat: 1.25
- highHeat: 1.15
- moderateHeat: 1.05
```

**SentinelNotificationFormatter.swift**
```swift
func formatNotification(alert, context) -> UNMutableNotificationContent
func formatShortNotification(alert, context) -> (title, body)

Contexts:
- Weather type specific
- Travel mode aware (car/walking)
- EV-specific recommendations
- Watch/Widget short format
```

### New UI Components

**ClimateAwareTimelineView.swift**
```swift
ClimateAwareTimelineView(
    slots: [DepartureSlot],
    selectedSlot: DepartureSlot?,
    onSelect: (DepartureSlot) -> Void
)

Components:
- TimelineBar: Individual time slot visualization
- HeatHazeOverlay: Wavy distortion animation
- SunFlareEffect: Radiating glow for extreme heat
- ClimateWarningBanner: Extreme heat alert banner
- ClimateLegendItem: Color coding explanation
```

## 📊 Data Flow

```
Route Calculation
    ↓
Climate Analysis (WizPathClimateService)
    ↓
Apply Multipliers (snow 2.2x, heat 1.25x, etc.)
    ↓
Generate Departure Slots
    ↓
Identify Sentinel-Worthy Slots (>30min or >40%)
    ↓
Format Notifications (weather-specific)
    ↓
Dispatch with Interruption Level
    ↓
Update UI (heat visualization + terminal output)
```

## 🎨 Design System

### Color Palette (Climate)
| Usage | Hex | Description |
|-------|-----|-------------|
| Optimal | #00FF41 | <32°C, no alerts |
| Moderate Heat | #FFCC00 | 32-36°C, caution |
| High Heat | #FF9500 | 36-40°C, warning |
| Extreme Heat | #FF3B30 | ≥40°C, critical |
| Heat Wave | #FF9500 | Animated haze |
| Sun Flare | #FFCC00 | Radiating glow |

### Typography
```swift
// Terminal-style headers
"> DEPARTURE_TIMELINE"
font: .system(size: 12, weight: .bold, design: .monospaced)
color: #00FF41

// Time labels
"08:00"
font: .system(size: 11, design: .monospaced)
color: white.opacity(0.7)

// Terminal output
"> CLIMATE_WARNING: Extreme Heat (42°C)..."
font: .system(size: 9, design: .monospaced)
color: white.opacity(0.6)
```

### Animation Specs
```swift
// Heat haze
.duration: 2.0
.repeatForever(autoreverses: true)
.easeInOut

// Sun flare pulse
.duration: 2.0
.repeatForever(autoreverses: true)
.intensity: 0.7 → 1.0

// Status dot
.duration: 1.0
.repeatForever(autoreverses: true)
.opacity: 0.5 → 1.0
```

## 📁 Files Added

```
ForeWiz/Features/WizPath/
├── Services/
│   ├── WizPathSentinelService.swift          (NEW)
│   ├── WizPathClimateService.swift            (NEW)
│   ├── DepartureOptimizerService.swift        (NEW)
│   └── SentinelNotificationFormatter.swift    (NEW)
└── Views/
    └── ClimateAwareTimelineView.swift        (NEW)
```

## 🔧 Usage Examples

### 1. Calculate Climate-Optimized Route
```swift
// Analyze climate impact
let analysis = climateService.analyzeRouteClimate(route, mode: .car)

// Apply adjustments
let adjusted = climateService.applyClimateAdjustment(to: route, analysis: analysis)

// Terminal output
print(adjusted.terminalOutput)
// "> CLIMATE_WARNING: Extreme Heat (42°C) detected. ETA adjusted +35min."
```

### 2. Evaluate Sentinel Alert
```swift
// Check if change warrants notification
let decision = sentinelService.evaluateRouteChange(
    originalRoute: oldRoute,
    updatedRoute: newRoute,
    weatherContext: context
)

switch decision {
case .trigger(let alert):
    await sentinelService.dispatchSentinelAlert(alert)
case .suppressed(let reason):
    print("Alert suppressed: \(reason.description)")
}
```

### 3. Display Climate Timeline
```swift
ClimateAwareTimelineView(
    slots: optimizationResult.slots,
    selectedSlot: selectedSlot,
    onSelect: { slot in
        // Handle selection
        print(slot.terminalOutput)
    }
)
```

### 4. Format Weather-Specific Notification
```swift
let context = NotificationContext(
    weatherType: .extremeHeat(temperature: 42),
    travelMode: .car,
    isEV: true,
    hasSafeStops: true,
    alternativeRoutesAvailable: false
)

let content = formatter.formatNotification(for: alert, context: context)
// Title: "🌡️ EXTREME HEAT: +45 min Added"
// Body: "ETA changed... 🔋 EV battery cooling required..."
```

## 🌡️ Climate Response Matrix

| Temperature | Car (ICE) | Car (EV) | Walking | UI Effect |
|-------------|-----------|----------|---------|-----------|
| <32°C | Normal | Normal | Normal | Green, no effects |
| 32-36°C | Normal | Normal | Caution | Yellow, minor haze |
| 36-38°C | Normal | ⚠️ Efficiency | 🚨 Health Risk | Orange, heat haze |
| 38-40°C | ⚠️ Breakdown Risk | 🚨 Battery | 🚨 Critical | Orange, stronger haze |
| ≥40°C | 🚨 Overheating | 🚨 Critical | 🚫 Avoid | Red, sun flare |

## 🚀 Next Steps

1. **Weather API Integration**
   - Real heat index calculation (feels like temp)
   - UV index integration for sun glare
   - Air quality (AQI) for health alerts

2. **Predictive AI**
   - ML model for heat impact on traffic
   - Historical pattern recognition
   - Personalized heat sensitivity profiles

3. **Smart Home Integration**
   - Pre-cool EV when plugged in
   - Home AC adjustment before arrival
   - Smart thermostat coordination

4. **Watch Complications**
   - Temperature on route
   - Time to next heat warning
   - Hydration reminders

## 📝 Localization Keys (New)

```
// Sentinel
sentinel_title_heat, sentinel_body_heat
sentinel_title_snow, sentinel_body_snow
sentinel_title_storm, sentinel_body_storm
sentinel_title_gridlock, sentinel_body_gridlock

// Climate
climate_ev_battery_title, climate_ev_battery_message
climate_heat_stroke_title, climate_heat_stroke_message
climate_infrastructure_title, climate_infrastructure_message

// Recommendations
rec_hydration_title, rec_shade_title, rec_timing_title
rec_ev_precool_title, rec_ev_speed_title, rec_ev_buffer_title

// Terminal
sentinel_slot_heat, sentinel_slot_gridlock
climate_rec_critical_heat, climate_rec_extreme_heat
```
