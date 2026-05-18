import Foundation
import CoreLocation
@preconcurrency import MapKit

// MARK: - Travel Mode
enum TravelMode: String, CaseIterable, Identifiable, Sendable {
    case car = "car"
    case walking = "walking"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .car: return "car.fill"
        case .walking: return "figure.walk"
        }
    }

    var localizedTitle: String {
        switch self {
        case .car: return L10n.text("wizpath_mode_car")
        case .walking: return L10n.text("wizpath_mode_walking")
        }
    }

    var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .car: return .automobile
        case .walking: return .walking
        }
    }

    var segmentInterval: TimeInterval {
        switch self {
        case .car: return 15 * 60
        case .walking: return 30 * 60
        }
    }

    var colorHex: String {
        switch self {
        case .car: return "#007AFF"
        case .walking: return "#FF9500"
        }
    }
}

// MARK: - WizPath Route
struct WizPathRoute: Identifiable, Equatable, Sendable {
    let id: UUID
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let travelMode: TravelMode
    let departureTime: Date
    let segments: [WizPathSegment]
    let totalDuration: TimeInterval
    let totalDistance: CLLocationDistance
    let polyline: MKPolyline?

    static func == (lhs: WizPathRoute, rhs: WizPathRoute) -> Bool {
        lhs.id == rhs.id &&
        lhs.origin.latitude == rhs.origin.latitude &&
        lhs.origin.longitude == rhs.origin.longitude &&
        lhs.destination.latitude == rhs.destination.latitude &&
        lhs.destination.longitude == rhs.destination.longitude &&
        lhs.travelMode == rhs.travelMode &&
        lhs.totalDuration == rhs.totalDuration &&
        lhs.totalDistance == rhs.totalDistance
    }

    /// Coordinates extracted from polyline for MapKit rendering
    var routeCoordinates: [CLLocationCoordinate2D] {
        guard let polyline = polyline else {
            // Fallback: use segment coordinates
            return segments.map { $0.coordinate }
        }
        let pointCount = polyline.pointCount
        guard pointCount > 0 else { return [] }
        let points = polyline.points()
        return (0..<pointCount).map { points[$0].coordinate }
    }

    var overallRisk: RouteRisk {
        let severe = segments.filter { $0.weather?.severity == .severe }
        let caution = segments.filter { $0.weather?.severity == .caution }
        if !severe.isEmpty { return .severe }
        if !caution.isEmpty { return .caution }
        return .good
    }

    var weatherChangePoints: [WizPathSegment] {
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
enum RouteRisk: String, Sendable {
    case good, caution, severe

    var color: String {
        switch self {
        case .good: return "#34C759"
        case .caution: return "#FF9500"
        case .severe: return "#FF3B30"
        }
    }

    var localizedTitle: String {
        switch self {
        case .good: return L10n.text("wizpath_risk_good")
        case .caution: return L10n.text("wizpath_risk_caution")
        case .severe: return L10n.text("wizpath_risk_severe")
        }
    }
}

// MARK: - WizPath Segment
struct WizPathSegment: Identifiable, Equatable, Sendable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let estimatedArrival: Date
    let distanceFromStart: CLLocationDistance
    let travelTime: TimeInterval
    var weather: SegmentWeather?

    static func == (lhs: WizPathSegment, rhs: WizPathSegment) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.estimatedArrival == rhs.estimatedArrival &&
        lhs.distanceFromStart == rhs.distanceFromStart &&
        lhs.travelTime == rhs.travelTime
    }

    var etaDisplay: String {
        SharedFormatters.shortTime.string(from: estimatedArrival)
    }
}

// MARK: - Segment Weather
struct SegmentWeather: Sendable {
    let condition: SegmentWeatherCondition
    let temperature: Double
    let precipitationChance: Double
    let windSpeed: Double
    let visibility: Double?
    let severity: SegmentWeatherSeverity

    var iconName: String { condition.iconName }
}

// MARK: - Weather Condition
enum SegmentWeatherCondition: String, Sendable, CaseIterable {
    case clear, partlyCloudy, cloudy, rain, heavyRain, snow, sleet, thunderstorm, fog, windy, unknown

    var iconName: String {
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

    var severity: SegmentWeatherSeverity {
        switch self {
        case .clear, .partlyCloudy: return .good
        case .cloudy, .windy: return .fair
        case .rain, .fog: return .caution
        case .heavyRain, .snow, .sleet, .thunderstorm: return .severe
        case .unknown: return .caution
        }
    }
}

// MARK: - Weather Severity
enum SegmentWeatherSeverity: String, Sendable {
    case good, fair, caution, severe

    var severityOrder: Int {
        switch self {
        case .good: return 0
        case .fair: return 1
        case .caution: return 2
        case .severe: return 3
        }
    }

    var colorHex: String {
        switch self {
        case .good: return "#34C759"
        case .fair: return "#FFCC00"
        case .caution: return "#FF9500"
        case .severe: return "#FF3B30"
        }
    }
}

// MARK: - WizPath Error
enum WizPathError: Error, LocalizedError {
    case routeUnavailable
    case noWalkingPath
    case weatherAPIFailed
    case destinationUnreachable
    case invalidDepartureTime

    var errorDescription: String? {
        switch self {
        case .routeUnavailable: return L10n.text("wizpath_error_route_blocked")
        case .noWalkingPath: return L10n.text("wizpath_error_no_walking")
        case .weatherAPIFailed: return L10n.text("wizpath_error_weather_unavailable")
        case .destinationUnreachable: return L10n.text("wizpath_error_unreachable")
        case .invalidDepartureTime: return L10n.text("wizpath_error_invalid_time")
        }
    }
}
