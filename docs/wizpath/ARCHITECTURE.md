# WizPath Architecture Blueprint

## Overview
Multi-modal (Driving/Walking) route-based weather forecasting system that calculates weather conditions at specific route points based on ETA.

## Core Architecture

### 1. Domain Layer (Models)
```
WizPathRoute
├── origin: CLLocationCoordinate2D
├── destination: CLLocationCoordinate2D
├── travelMode: TravelMode (car/walking)
├── departureTime: Date
├── segments: [WizPathSegment]
└── totalDuration: TimeInterval

WizPathSegment
├── coordinate: CLLocationCoordinate2D
├── estimatedArrival: Date
├── weather: SegmentWeather
├── distanceFromStart: CLLocationDistance
└── travelTime: TimeInterval

SegmentWeather
├── condition: WeatherCondition
├── temperature: Double
├── precipitationChance: Double
├── windSpeed: Double
└── severity: WeatherSeverity
```

### 2. Service Layer
```
WizPathService (Actor)
├── calculateRoute(origin, destination, mode, departureTime) -> WizPathRoute
├── interpolateSegments(route: MKRoute) -> [WizPathSegment]
├── fetchWeatherForSegments([WizPathSegment]) -> [SegmentWeather]
└── throttleWeatherRequests(segments) -> ThrottledBatchRequest

RouteCalculationService
├── calculateDrivingRoute() -> MKDirections.Response
├── calculateWalkingRoute() -> MKDirections.Response
└── handleRouteError() -> WizPathError

WeatherTimelineService
├── fetchWeatherForCoordinateAtTime(coord, time) -> WeatherPoint
├── batchFetchWeather([CoordinateTimePair]) -> [WeatherPoint]
└── cacheWeatherResults() -> WeatherCache
```

### 3. UI Layer
```
WizPathDashboardView (Root)
├── TripPlannerView
│   ├── DestinationPicker (Map + Search)
│   ├── DepartureTimePicker
│   └── TravelModeToggle [Car | Walking]
├── WizPathMapView
│   ├── MKMapView with Route Overlay
│   ├── WeatherIconOverlay (Neon Green/Orange/Red)
│   ├── ETAMarkerAnnotations
│   └── DangerZoneHighlights
└── WizPathDetailView
    ├── SegmentCards
    ├── WeatherTimeline
    └── RiskSummary
```

### 4. Design System
- **Route Line**: Neon Green (#00FF41) base, Orange (#FF9500) for caution, Red (#FF3B30) for danger
- **Background**: AMOLED Black (#000000) with glass morphism cards
- **Weather Icons**: SF Symbols with neon color coding
- **Typography**: SF Pro Rounded, white with opacity hierarchy

## Data Flow

```
User selects destination
    ↓
MKDirections calculates route (Car/Walking)
    ↓
RouteInterpolation breaks into time-segments
    ↓
WeatherTimelineService fetches weather for each ETA
    ↓
WizPathBuilder combines route + weather
    ↓
Map renders with color-coded route + weather icons
    ↓
Traffic updates trigger ETA recalculation + weather refresh
```

## Performance Strategy

### API Throttling
- Batch weather requests: max 5 concurrent calls
- Segment sampling: Every 15-30 mins of travel time
- Cache weather results: 15-minute TTL
- Debounce traffic updates: 30-second minimum

### Memory Management
- Limit active segments to 20 max
- Unload off-screen map annotations
- Use lightweight MKPolyline vs MKPolygon

## Error Handling

### Route Errors
- **Unreachable**: "Route Blocked / System Error" (Matrix-style)
- **No Walking Path**: "This route requires a vehicle"
- **Weather API Fail**: "Limited forecast available - check connection"

### Weather Severity Mapping
```swift
.neonGreen: Good conditions (score 70-100)
.neonOrange: Caution (score 40-69, rain/wind)
.neonRed: Dangerous (score <40, severe weather)
```
