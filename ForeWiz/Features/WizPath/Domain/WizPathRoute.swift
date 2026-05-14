import Foundation
import CoreLocation
@preconcurrency import MapKit

// MARK: - Travel Mode
enum TravelMode: String, CaseIterable, Identifiable {
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
    
    /// Time interval between weather checkpoints
    var segmentInterval: TimeInterval {
        switch self {
        case .car: return 15 * 60 // Check every 15 mins for driving
        case .walking: return 30 * 60 // Check every 30 mins for walking
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
    
    /// Weather severity summary for the entire route
    var overallRisk: RouteRisk {
        let severeSegments = segments.filter { $0.weather?.severity == .severe }
        let cautionSegments = segments.filter { $0.weather?.severity == .caution }
        
        if !severeSegments.isEmpty { return .severe }
        if !cautionSegments.isEmpty { return .caution }
        return .good
    }
    
    /// Segments where weather changes significantly
    var weatherChangePoints: [WizPathSegment] {
        guard segments.count > 1 else { return segments }
        
        var changes: [WizPathSegment] = [segments[0]]
        
        for i in 1..<segments.count {
            let current = segments[i]
            let previous = segments[i-1]
            
            // Include if weather condition changes
            if current.weather?.condition != previous.weather?.condition {
                changes.append(current)
            }
            // Include if severity changes
            else if current.weather?.severity != previous.weather?.severity {
                changes.append(current)
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
        case .good: return "#00FF41" // Neon Green
        case .caution: return "#FF9500" // Orange
        case .severe: return "#FF3B30" // Red
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
    let travelTime: TimeInterval // Time from start to this segment
    var weather: SegmentWeather?
    
    static func == (lhs: WizPathSegment, rhs: WizPathSegment) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.estimatedArrival == rhs.estimatedArrival &&
        lhs.distanceFromStart == rhs.distanceFromStart &&
        lhs.travelTime == rhs.travelTime
    }
    
    /// ETA formatted for display
    var etaDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: estimatedArrival)
    }
}

// MARK: - Segment Weather
struct SegmentWeather: Sendable {
    let condition: SegmentWeatherCondition
    let temperature: Double // Celsius
    let precipitationChance: Double // 0-1
    let windSpeed: Double // km/h
    let visibility: Double? // km
    let severity: SegmentWeatherSeverity
    
    /// Icon name for this weather condition
    var iconName: String {
        condition.iconName
    }
}

// MARK: - Weather Condition
enum SegmentWeatherCondition: String, Sendable {
    case clear, partlyCloudy, cloudy, rain, heavyRain, snow, thunderstorm, fog, unknown
    
    var iconName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .fog: return "cloud.fog.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var severity: SegmentWeatherSeverity {
        switch self {
        case .clear, .partlyCloudy: return .good
        case .cloudy: return .fair
        case .rain, .fog: return .caution
        case .heavyRain, .snow, .thunderstorm: return .severe
        case .unknown: return .caution
        }
    }
}

// MARK: - Weather Severity
enum SegmentWeatherSeverity: String, Sendable {
    case good, fair, caution, severe
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
        case .routeUnavailable:
            return L10n.text("wizpath_error_route_blocked")
        case .noWalkingPath:
            return L10n.text("wizpath_error_no_walking")
        case .weatherAPIFailed:
            return L10n.text("wizpath_error_weather_unavailable")
        case .destinationUnreachable:
            return L10n.text("wizpath_error_unreachable")
        case .invalidDepartureTime:
            return L10n.text("wizpath_error_invalid_time")
        }
    }
}
