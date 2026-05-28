import Foundation
import CoreLocation
@preconcurrency import MapKit

// MARK: - Smart Stop (Weather-Aware POI)
public struct SmartStop: Identifiable, Sendable, Equatable {
    public static func == (lhs: SmartStop, rhs: SmartStop) -> Bool {
        lhs.id == rhs.id
    }
    public let id: UUID
    public let mapItem: MKMapItem
    public let coordinate: CLLocationCoordinate2D
    public let name: String
    public let category: POICategory
    public let etaArrival: Date
    public let weatherAtArrival: SegmentWeather?
    public let safetyStatus: POISafetyStatus
    public let distanceFromRoute: CLLocationDistance
    public let estimatedStopDuration: TimeInterval
    public let weatherRecommendation: String?

    public init(id: UUID, mapItem: MKMapItem, coordinate: CLLocationCoordinate2D, name: String,
                category: POICategory, etaArrival: Date, weatherAtArrival: SegmentWeather?,
                safetyStatus: POISafetyStatus, distanceFromRoute: CLLocationDistance, estimatedStopDuration: TimeInterval,
                weatherRecommendation: String? = nil) {
        self.id = id
        self.mapItem = mapItem
        self.coordinate = coordinate
        self.name = name
        self.category = category
        self.etaArrival = etaArrival
        self.weatherAtArrival = weatherAtArrival
        self.safetyStatus = safetyStatus
        self.distanceFromRoute = distanceFromRoute
        self.estimatedStopDuration = estimatedStopDuration
        self.weatherRecommendation = weatherRecommendation
    }

    public var displayTitle: String {
        name.isEmpty ? category.defaultName : name
    }

    public var isRecommended: Bool {
        safetyStatus == .safe || safetyStatus == .caution
    }

    public var etaDisplay: String {
        WizPathKitFormatters.shortTime.string(from: etaArrival)
    }
}

// MARK: - POI Category
public enum POICategory: String, Sendable {
    case gasStation
    case evCharger
    case restStop
    case restaurant

    public var mkCategory: MKPointOfInterestCategory? {
        switch self {
        case .gasStation: return .gasStation
        case .evCharger: return .evCharger
        case .restStop: return nil
        case .restaurant: return .restaurant
        }
    }

    public var iconName: String {
        switch self {
        case .gasStation: return "fuelpump.fill"
        case .evCharger: return "bolt.car.fill"
        case .restStop: return "bed.double.fill"
        case .restaurant: return "fork.knife"
        }
    }

    public var defaultName: String {
        switch self {
        case .gasStation: return WizPathKitL10n.text("poi_gas_station")
        case .evCharger: return WizPathKitL10n.text("poi_ev_charger")
        case .restStop: return WizPathKitL10n.text("poi_rest_stop")
        case .restaurant: return WizPathKitL10n.text("poi_restaurant")
        }
    }

    public var color: String {
        switch self {
        case .gasStation: return "#00FF41"
        case .evCharger: return "#00D9FF"
        case .restStop: return "#FF9500"
        case .restaurant: return "#FF3BFF"
        }
    }
}

// MARK: - POI Safety Status
public enum POISafetyStatus: String, Sendable {
    case safe
    case caution
    case unsafe
    case dangerous

    public var color: String {
        switch self {
        case .safe: return "#00FF41"
        case .caution: return "#FFCC00"
        case .unsafe: return "#FF9500"
        case .dangerous: return "#FF3B30"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .safe: return WizPathKitL10n.text("poi_status_safe")
        case .caution: return WizPathKitL10n.text("poi_status_caution")
        case .unsafe: return WizPathKitL10n.text("poi_status_unsafe")
        case .dangerous: return WizPathKitL10n.text("poi_status_dangerous")
        }
    }

    public var shouldAvoid: Bool {
        self == .unsafe || self == .dangerous
    }
}

// MARK: - Environmental Hazard
public struct EnvironmentalHazard: Identifiable, Sendable {
    public let id: UUID
    public let type: HazardType
    public let coordinate: CLLocationCoordinate2D
    public let routeSegmentIndex: Int
    public let severity: HazardSeverity
    public let details: String
    public let recommendation: String
    public let etaAtLocation: Date

    public init(id: UUID, type: HazardType, coordinate: CLLocationCoordinate2D, routeSegmentIndex: Int,
                severity: HazardSeverity, details: String, recommendation: String, etaAtLocation: Date) {
        self.id = id
        self.type = type
        self.coordinate = coordinate
        self.routeSegmentIndex = routeSegmentIndex
        self.severity = severity
        self.details = details
        self.recommendation = recommendation
        self.etaAtLocation = etaAtLocation
    }

    public var localizedTitle: String { type.localizedTitle }
    public var iconName: String { type.iconName }
}

// MARK: - Hazard Type
public enum HazardType: String, Sendable {
    case crosswind
    case sunGlare
    case heavyRain
    case snow
    case thunderstorm
    case fog
    case ice

    public var iconName: String {
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

    public var localizedTitle: String {
        switch self {
        case .crosswind: return WizPathKitL10n.text("hazard_crosswind")
        case .sunGlare: return WizPathKitL10n.text("hazard_sun_glare")
        case .heavyRain: return WizPathKitL10n.text("hazard_heavy_rain")
        case .snow: return WizPathKitL10n.text("hazard_snow")
        case .thunderstorm: return WizPathKitL10n.text("hazard_thunderstorm")
        case .fog: return WizPathKitL10n.text("hazard_fog")
        case .ice: return WizPathKitL10n.text("hazard_ice")
        }
    }

    public var vehicleTypesAffected: [TravelMode] {
        switch self {
        case .crosswind: return [.car, .walking]
        case .sunGlare: return [.car]
        case .heavyRain, .snow, .thunderstorm, .fog, .ice: return [.car, .walking]
        }
    }
}

// MARK: - Hazard Severity
public enum HazardSeverity: String, Sendable {
    case low, moderate, high, critical

    public var color: String {
        switch self {
        case .low: return "#00FF41"
        case .moderate: return "#FFCC00"
        case .high: return "#FF9500"
        case .critical: return "#FF3B30"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .low: return WizPathKitL10n.text("hazard_severity_low")
        case .moderate: return WizPathKitL10n.text("hazard_severity_moderate")
        case .high: return WizPathKitL10n.text("hazard_severity_high")
        case .critical: return WizPathKitL10n.text("hazard_severity_critical")
        }
    }
}

// MARK: - Journey HUD Data
public struct JourneyHUDData: Sendable {
    public let totalDuration: TimeInterval
    public let totalDistance: CLLocationDistance
    public let hazardCount: Int
    public let safeStops: Int
    public let safetyScore: Int
    public let activeHazards: [EnvironmentalHazard]
    public let nextSafeStop: SmartStop?

    public init(totalDuration: TimeInterval, totalDistance: CLLocationDistance, hazardCount: Int,
                safeStops: Int, safetyScore: Int, activeHazards: [EnvironmentalHazard], nextSafeStop: SmartStop?) {
        self.totalDuration = totalDuration
        self.totalDistance = totalDistance
        self.hazardCount = hazardCount
        self.safeStops = safeStops
        self.safetyScore = safetyScore
        self.activeHazards = activeHazards
        self.nextSafeStop = nextSafeStop
    }

    public var durationDisplay: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return WizPathKitL10n.formatted("format_duration_hours_minutes", hours, minutes)
        } else {
            return WizPathKitL10n.formatted("format_duration_minutes_only", minutes)
        }
    }
}
