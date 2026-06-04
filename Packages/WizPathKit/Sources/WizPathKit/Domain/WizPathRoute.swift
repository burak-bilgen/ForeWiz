import Foundation
import CoreLocation
@preconcurrency import MapKit

// MARK: - Travel Mode
public enum TravelMode: String, CaseIterable, Identifiable, Sendable {
    case car = "car"
    case walking = "walking"
    case cycling = "cycling"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .car: return "car.fill"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .car: return WizPathKitL10n.text("wizpath_mode_car")
        case .walking: return WizPathKitL10n.text("wizpath_mode_walking")
        case .cycling: return WizPathKitL10n.text("wizpath_mode_cycling")
        }
    }

    public var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .car: return .automobile
        case .walking: return .walking
        case .cycling: return .cycling
        }
    }

    public var segmentInterval: TimeInterval {
        switch self {
        case .car: return 15 * 60
        case .walking: return 30 * 60
        case .cycling: return 10 * 60  // More frequent segments for cycling (wind changes matter)
        }
    }

    public var colorHex: String {
        switch self {
        case .car: return "#007AFF"
        case .walking: return "#FF9500"
        case .cycling: return "#34C759"
        }
    }

    /// Average speed in km/h for travel time estimation
    public var averageSpeedKph: Double {
        switch self {
        case .car: return 40
        case .walking: return 5
        case .cycling: return 15
        }
    }

    /// Whether this mode is vulnerable to crosswind
    public var isWindSensitive: Bool {
        switch self {
        case .cycling: return true
        case .car, .walking: return false
        }
    }
}

// MARK: - WizPath Route
public struct WizPathRoute: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let origin: CLLocationCoordinate2D
    public let destination: CLLocationCoordinate2D
    public let travelMode: TravelMode
    public let departureTime: Date
    public let segments: [WizPathSegment]
    public let totalDuration: TimeInterval
    public let totalDistance: CLLocationDistance
    public let polyline: MKPolyline?

    public init(id: UUID, origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D,
                travelMode: TravelMode, departureTime: Date, segments: [WizPathSegment],
                totalDuration: TimeInterval, totalDistance: CLLocationDistance, polyline: MKPolyline?) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.travelMode = travelMode
        self.departureTime = departureTime
        self.segments = segments
        self.totalDuration = totalDuration
        self.totalDistance = totalDistance
        self.polyline = polyline
    }

    public static func == (lhs: WizPathRoute, rhs: WizPathRoute) -> Bool {
        lhs.id == rhs.id &&
        lhs.origin.latitude == rhs.origin.latitude &&
        lhs.origin.longitude == rhs.origin.longitude &&
        lhs.destination.latitude == rhs.destination.latitude &&
        lhs.destination.longitude == rhs.destination.longitude &&
        lhs.travelMode == rhs.travelMode &&
        lhs.totalDuration == rhs.totalDuration &&
        lhs.totalDistance == rhs.totalDistance
    }

    public var routeCoordinates: [CLLocationCoordinate2D] {
        guard let polyline = polyline else {
            return segments.map { $0.coordinate }
        }
        let pointCount = polyline.pointCount
        guard pointCount > 0 else { return [] }
        let points = polyline.points()
        return (0..<pointCount).map { points[$0].coordinate }
    }

    public var overallRisk: RouteRisk {
        let severe = segments.filter { $0.weather?.severity == .severe }
        let caution = segments.filter { $0.weather?.severity == .caution }
        if !severe.isEmpty { return .severe }
        if !caution.isEmpty { return .caution }
        return .good
    }

    public var weatherChangePoints: [WizPathSegment] {
        guard segments.count > 1 else { return segments }
        var changes: [WizPathSegment] = [segments[0]]
        for i in 1..<segments.count {
            let cur = segments[i]
            let prev = segments[i-1]
            if cur.weather?.condition != prev.weather?.condition
                || cur.weather?.severity != prev.weather?.severity {
                changes.append(cur)
            }
        }
        return changes
    }
}

// MARK: - Route Risk
public enum RouteRisk: String, Sendable {
    case good, caution, severe

    public var color: String {
        switch self {
        case .good: return "#34C759"
        case .caution: return "#FF9500"
        case .severe: return "#FF3B30"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .good: return WizPathKitL10n.text("wizpath_risk_good")
        case .caution: return WizPathKitL10n.text("wizpath_risk_caution")
        case .severe: return WizPathKitL10n.text("wizpath_risk_severe")
        }
    }
}

// MARK: - WizPath Segment
public struct WizPathSegment: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let coordinate: CLLocationCoordinate2D
    public let estimatedArrival: Date
    public let distanceFromStart: CLLocationDistance
    public let travelTime: TimeInterval
    public var weather: SegmentWeather?
    /// Human-readable place name resolved via reverse geocoding (e.g. "Kadıköy", "Levent")
    public var placeName: String?

    public init(id: UUID, coordinate: CLLocationCoordinate2D, estimatedArrival: Date,
                distanceFromStart: CLLocationDistance, travelTime: TimeInterval, weather: SegmentWeather? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.estimatedArrival = estimatedArrival
        self.distanceFromStart = distanceFromStart
        self.travelTime = travelTime
        self.weather = weather
        self.placeName = nil
    }

    public static func == (lhs: WizPathSegment, rhs: WizPathSegment) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.estimatedArrival == rhs.estimatedArrival &&
        lhs.distanceFromStart == rhs.distanceFromStart &&
        lhs.travelTime == rhs.travelTime
    }

    public var etaDisplay: String {
        WizPathKitFormatters.shortTime.string(from: estimatedArrival)
    }
}

// MARK: - Segment Weather
public struct SegmentWeather: Sendable {
    public let condition: SegmentWeatherCondition
    public let temperature: Double
    public let precipitationChance: Double
    public let windSpeed: Double
    public let visibility: Double?
    public let severity: SegmentWeatherSeverity

    public init(condition: SegmentWeatherCondition, temperature: Double, precipitationChance: Double,
                windSpeed: Double, visibility: Double? = nil, severity: SegmentWeatherSeverity) {
        self.condition = condition
        self.temperature = temperature
        self.precipitationChance = precipitationChance
        self.windSpeed = windSpeed
        self.visibility = visibility
        self.severity = severity
    }

    public var iconName: String { condition.iconName }
}

// MARK: - Weather Condition
public enum SegmentWeatherCondition: String, Sendable, CaseIterable {
    case clear, partlyCloudy, cloudy, rain, heavyRain, snow, sleet, thunderstorm, fog, windy, unknown

    public var iconName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .snow: return "cloud.snow.fill"
        case .sleet: return "cloud.sleet.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .fog: return "cloud.fog.fill"
        case .windy: return "wind"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    public var severity: SegmentWeatherSeverity {
        switch self {
        case .clear, .partlyCloudy: return .good
        case .cloudy, .windy: return .fair
        case .rain, .fog: return .caution
        case .heavyRain, .snow, .sleet, .thunderstorm: return .severe
        case .unknown: return .caution
        }
    }

    /// Map route polyline color — colors the route by predicted weather condition
    public var mapRouteColor: String {
        switch self {
        case .clear, .partlyCloudy: return "#34C759"     // green
        case .cloudy: return "#AEAEB2"                     // gray
        case .rain: return "#007AFF"                        // blue
        case .heavyRain: return "#003EFF"                   // dark blue
        case .snow: return "#C7C7E5"                        // periwinkle
        case .sleet: return "#8E8EE6"                       // slate
        case .thunderstorm: return "#AF52DE"                // purple
        case .fog: return "#636366"                         // dark gray
        case .windy: return "#FF9500"                       // orange
        case .unknown: return "#8E8E93"
        }
    }

    /// Human-readable localized display title for this weather condition.
    public var localizedTitle: String {
        switch self {
        case .clear: return WizPathKitL10n.text("wizpath_condition_clear")
        case .partlyCloudy: return WizPathKitL10n.text("wizpath_condition_partly_cloudy")
        case .cloudy: return WizPathKitL10n.text("wizpath_condition_cloudy")
        case .rain: return WizPathKitL10n.text("wizpath_condition_rain")
        case .heavyRain: return WizPathKitL10n.text("wizpath_condition_heavy_rain")
        case .snow: return WizPathKitL10n.text("wizpath_condition_snow")
        case .sleet: return WizPathKitL10n.text("wizpath_condition_sleet")
        case .thunderstorm: return WizPathKitL10n.text("wizpath_condition_thunderstorm")
        case .fog: return WizPathKitL10n.text("wizpath_condition_fog")
        case .windy: return WizPathKitL10n.text("wizpath_condition_windy")
        case .unknown: return WizPathKitL10n.text("wizpath_condition_unknown")
        }
    }

    /// Marker accent color on the map
    public var mapMarkerColor: String {
        switch self {
        case .clear, .partlyCloudy: return "#34C759"
        case .cloudy: return "#8E8E93"
        case .rain, .heavyRain, .snow, .sleet: return "#5AC8FA"
        case .thunderstorm: return "#AF52DE"
        case .fog: return "#8E8E93"
        case .windy: return "#FF9500"
        case .unknown: return "#8E8E93"
        }
    }
}

// MARK: - Weather Severity
public enum SegmentWeatherSeverity: String, Sendable {
    case good, fair, caution, severe

    public var severityOrder: Int {
        switch self {
        case .good: return 0
        case .fair: return 1
        case .caution: return 2
        case .severe: return 3
        }
    }

    public var colorHex: String {
        switch self {
        case .good: return "#34C759"
        case .fair: return "#FFCC00"
        case .caution: return "#FF9500"
        case .severe: return "#FF3B30"
        }
    }
}

// MARK: - Traffic Congestion Level
public enum TrafficCongestionLevel: String, Sendable, Comparable {
    case unknown = "unknown"
    case freeFlow = "free_flow"
    case moderate = "moderate"
    case heavy = "heavy"
    case gridlock = "gridlock"

    public var severityOrder: Int {
        switch self {
        case .unknown: return 0
        case .freeFlow: return 1
        case .moderate: return 2
        case .heavy: return 3
        case .gridlock: return 4
        }
    }

    public static func < (lhs: TrafficCongestionLevel, rhs: TrafficCongestionLevel) -> Bool {
        lhs.severityOrder < rhs.severityOrder
    }

    public var colorHex: String {
        switch self {
        case .unknown: return "#8E8E93"
        case .freeFlow: return "#34C759"
        case .moderate: return "#FFCC00"
        case .heavy: return "#FF9500"
        case .gridlock: return "#FF3B30"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .unknown: return WizPathKitL10n.text("traffic_unknown")
        case .freeFlow: return WizPathKitL10n.text("traffic_free_flow")
        case .moderate: return WizPathKitL10n.text("traffic_moderate")
        case .heavy: return WizPathKitL10n.text("traffic_heavy")
        case .gridlock: return WizPathKitL10n.text("traffic_gridlock")
        }
    }
}

// MARK: - Scored Route Candidate (for comparison)
public struct ScoredRouteCandidate: Identifiable, Sendable {
    public let id: UUID
    public let route: WizPathRoute
    public let score: Int
    public let trafficCongestion: TrafficCongestionLevel
    public let hasTollRoads: Bool
    public let severeSegmentCount: Int
    public let cautionSegmentCount: Int

    public init(route: WizPathRoute, score: Int, trafficCongestion: TrafficCongestionLevel = .unknown,
                hasTollRoads: Bool = false, severeSegmentCount: Int = 0, cautionSegmentCount: Int = 0) {
        self.id = route.id
        self.route = route
        self.score = score
        self.trafficCongestion = trafficCongestion
        self.hasTollRoads = hasTollRoads
        self.severeSegmentCount = severeSegmentCount
        self.cautionSegmentCount = cautionSegmentCount
    }

    public var isBest: Bool { score >= 80 }
    public var isGood: Bool { score >= 60 && score < 80 }
    public var isModerate: Bool { score >= 40 && score < 60 }
    public var isPoor: Bool { score < 40 }

    public var scoreLabel: String {
        if isBest { return WizPathKitL10n.text("route_score_best") }
        if isGood { return WizPathKitL10n.text("route_score_good") }
        if isModerate { return WizPathKitL10n.text("route_score_moderate") }
        return WizPathKitL10n.text("route_score_poor")
    }

    public var scoreColorHex: String {
        if isBest { return "#34C759" }
        if isGood { return "#30D158" }
        if isModerate { return "#FFCC00" }
        return "#FF3B30"
    }

    public var formattedDuration: String {
        let h = Int(route.totalDuration) / 3600
        let m = (Int(route.totalDuration) % 3600) / 60
        if h > 0 { return WizPathKitL10n.formatted("format_duration_hours_minutes", h, m) }
        return WizPathKitL10n.formatted("format_duration_minutes_only", m)
    }

    public var formattedDistance: String {
        let km = route.totalDistance / 1000
        let unit = WizPathKitL10n.text("unit_km")
        if km >= 10 {
            return "\(Int(km)) \(unit)"
        }
        return String(format: "%.1f %@", locale: Locale.current, km as CVarArg, unit)
    }
}

// MARK: - WizPath Error
public enum WizPathError: Error, LocalizedError {
    case routeUnavailable
    case noWalkingPath
    case weatherAPIFailed
    case destinationUnreachable
    case invalidDepartureTime
    case timeout

    public var errorDescription: String? {
        switch self {
        case .routeUnavailable: return WizPathKitL10n.text("wizpath_error_route_blocked")
        case .noWalkingPath: return WizPathKitL10n.text("wizpath_error_no_walking")
        case .weatherAPIFailed: return WizPathKitL10n.text("wizpath_error_weather_unavailable")
        case .destinationUnreachable: return WizPathKitL10n.text("wizpath_error_unreachable")
        case .invalidDepartureTime: return WizPathKitL10n.text("wizpath_error_invalid_time")
        case .timeout: return WizPathKitL10n.text("wizpath_error_timeout")
        }
    }
}
