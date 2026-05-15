import Foundation
import CoreLocation
@preconcurrency import MapKit

// MARK: - Smart Stop (Weather-Aware POI)
struct SmartStop: Identifiable, Sendable {
    let id: UUID
    let mapItem: MKMapItem
    let coordinate: CLLocationCoordinate2D
    let name: String
    let category: POICategory
    let etaArrival: Date
    let weatherAtArrival: SegmentWeather?
    let safetyStatus: POISafetyStatus
    let distanceFromRoute: CLLocationDistance
    let estimatedStopDuration: TimeInterval // How long to stop here
    
    /// Display title for UI
    var displayTitle: String {
        name.isEmpty ? category.defaultName : name
    }
    
    /// Safety assessment based on weather
    var isRecommended: Bool {
        safetyStatus == .safe || safetyStatus == .caution
    }
    
    /// Formatted ETA string
    var etaDisplay: String {
        SharedFormatters.shortTime.string(from: etaArrival)
    }
}

// MARK: - POI Category
enum POICategory: String, Sendable {
    case gasStation
    case evCharger
    case restStop
    case restaurant
    
    var mkCategory: MKPointOfInterestCategory? {
        switch self {
        case .gasStation: return .gasStation
        case .evCharger: return .evCharger
        case .restStop: return nil // Custom search needed
        case .restaurant: return .restaurant
        }
    }
    
    var iconName: String {
        switch self {
        case .gasStation: return "fuel.pump.fill"
        case .evCharger: return "bolt.car.fill"
        case .restStop: return "bed.double.fill"
        case .restaurant: return "fork.knife"
        }
    }
    
    var defaultName: String {
        switch self {
        case .gasStation: return L10n.text("poi_gas_station")
        case .evCharger: return L10n.text("poi_ev_charger")
        case .restStop: return L10n.text("poi_rest_stop")
        case .restaurant: return L10n.text("poi_restaurant")
        }
    }
    
    var color: String {
        switch self {
        case .gasStation: return "#00FF41" // Neon Green
        case .evCharger: return "#00D9FF" // Electric Blue
        case .restStop: return "#FF9500" // Orange
        case .restaurant: return "#FF3BFF" // Neon Pink
        }
    }
}

// MARK: - POI Safety Status
enum POISafetyStatus: String, Sendable {
    case safe      // Clear weather, good conditions
    case caution   // Light rain, manageable
    case unsafe    // Heavy rain, snow, storms
    case dangerous // Severe weather, avoid
    
    var color: String {
        switch self {
        case .safe: return "#00FF41" // Neon Green
        case .caution: return "#FFCC00" // Yellow
        case .unsafe: return "#FF9500" // Orange
        case .dangerous: return "#FF3B30" // Red
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .safe: return L10n.text("poi_status_safe")
        case .caution: return L10n.text("poi_status_caution")
        case .unsafe: return L10n.text("poi_status_unsafe")
        case .dangerous: return L10n.text("poi_status_dangerous")
        }
    }
    
    var shouldAvoid: Bool {
        self == .unsafe || self == .dangerous
    }
}

// MARK: - Environmental Hazard
struct EnvironmentalHazard: Identifiable, Sendable {
    let id: UUID
    let type: HazardType
    let coordinate: CLLocationCoordinate2D
    let routeSegmentIndex: Int
    let severity: HazardSeverity
    let details: String
    let recommendation: String
    let etaAtLocation: Date
    
    var localizedTitle: String {
        type.localizedTitle
    }
    
    var iconName: String {
        type.iconName
    }
}

// MARK: - Hazard Type
enum HazardType: String, Sendable {
    case crosswind
    case sunGlare
    case heavyRain
    case snow
    case thunderstorm
    case fog
    case ice
    
    var iconName: String {
        switch self {
        case .crosswind: return "wind"
        case .sunGlare: return "sun.max"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .snow: return "snowflake"
        case .thunderstorm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        case .ice: return "thermometer.snowflake"
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .crosswind: return L10n.text("hazard_crosswind")
        case .sunGlare: return L10n.text("hazard_sun_glare")
        case .heavyRain: return L10n.text("hazard_heavy_rain")
        case .snow: return L10n.text("hazard_snow")
        case .thunderstorm: return L10n.text("hazard_thunderstorm")
        case .fog: return L10n.text("hazard_fog")
        case .ice: return L10n.text("hazard_ice")
        }
    }
    
    var vehicleTypesAffected: [TravelMode] {
        switch self {
        case .crosswind: return [.car, .walking] // Motorcycles especially
        case .sunGlare: return [.car] // All vehicles
        case .heavyRain, .snow, .thunderstorm, .fog, .ice: return [.car, .walking]
        }
    }
}

// MARK: - Hazard Severity
enum HazardSeverity: String, Sendable {
    case low, moderate, high, critical
    
    var color: String {
        switch self {
        case .low: return "#00FF41"
        case .moderate: return "#FFCC00"
        case .high: return "#FF9500"
        case .critical: return "#FF3B30"
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .low: return L10n.text("hazard_severity_low")
        case .moderate: return L10n.text("hazard_severity_moderate")
        case .high: return L10n.text("hazard_severity_high")
        case .critical: return L10n.text("hazard_severity_critical")
        }
    }
}


// MARK: - Journey HUD Data
struct JourneyHUDData: Sendable {
    let totalDuration: TimeInterval
    let totalDistance: CLLocationDistance
    let hazardCount: Int
    let safeStops: Int
    let safetyScore: Int
    let activeHazards: [EnvironmentalHazard]
    let nextSafeStop: SmartStop?
    
    var durationDisplay: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return String(format: "%d\(L10n.text("unit_hour_short")) %02d\(L10n.text("unit_minute_short"))", hours, minutes)
        } else {
            return String(format: "%d \(L10n.text("unit_minutes"))", minutes)
        }
    }
}
