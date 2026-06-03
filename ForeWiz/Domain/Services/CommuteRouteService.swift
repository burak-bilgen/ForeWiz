import Foundation
import CoreLocation

enum TravelMode: String, CaseIterable, Sendable {
    case car
    case walking
    case cycling
    case transit

    var averageSpeedKph: Double {
        switch self {
        case .car: return 40
        case .walking: return 5
        case .cycling: return 15
        case .transit: return 25
        }
    }

    var isWindSensitive: Bool {
        switch self {
        case .car, .transit: return false
        case .walking: return false
        case .cycling: return true
        }
    }

    var localizedKey: String {
        switch self {
        case .car: return "travel_mode_car"
        case .walking: return "travel_mode_walking"
        case .cycling: return "travel_mode_cycling"
        case .transit: return "travel_mode_transit"
        }
    }

    var iconName: String {
        switch self {
        case .car: return "car.fill"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .transit: return "bus.fill"
        }
    }
}

struct CommuteRoute: Equatable, Sendable {
    var origin: SavedLocation
    var destination: SavedLocation
    var distanceKm: Double
    var estimatedDurationMinutes: Int
    var mode: TravelMode
    var weatherHazards: [String]
}

struct CommuteWeatherImpact: Equatable, Sendable {
    var overallScore: Int
    var hazardWarnings: [String]
    var bestDepartureWindow: String?
}

struct CommuteBriefing: Equatable, Sendable {
    var summary: String
    var weatherAtOrigin: String
    var weatherAtDestination: String
    var routeHazards: [String]
    var recommendation: String
}

enum CommuteRouteError: LocalizedError {
    case homeNotSet
    case workNotSet
    case originNotHomeOrWork
    case destinationNotHomeOrWork

    var errorDescription: String? {
        switch self {
        case .homeNotSet: return "Home location is not set."
        case .workNotSet: return "Work location is not set."
        case .originNotHomeOrWork: return "Origin must be a home or work location."
        case .destinationNotHomeOrWork: return "Destination must be a home or work location."
        }
    }
}

protocol CommuteRouteService {
    func calculateCommute(from origin: SavedLocation, to destination: SavedLocation, mode: TravelMode) async throws -> CommuteRoute
    func weatherImpact(on route: CommuteRoute) async -> CommuteWeatherImpact
    func commuteBriefing(home: SavedLocation, work: SavedLocation, mode: TravelMode) async -> CommuteBriefing
}

struct DefaultCommuteRouteService: CommuteRouteService {
    private let haversineDistance: (SavedLocation, SavedLocation) -> Double = { origin, destination in
        let lat1 = origin.latitude * .pi / 180
        let lon1 = origin.longitude * .pi / 180
        let lat2 = destination.latitude * .pi / 180
        let lon2 = destination.longitude * .pi / 180
        let dlat = lat2 - lat1
        let dlon = lon2 - lon1
        let a = sin(dlat / 2) * sin(dlat / 2) + cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return 6371 * c
    }

    func calculateCommute(from origin: SavedLocation, to destination: SavedLocation, mode: TravelMode) async throws -> CommuteRoute {
        let distanceKm = haversineDistance(origin, destination)
        let estimatedDurationMinutes = max(1, Int((distanceKm / mode.averageSpeedKph) * 60))
        let weatherHazards: [String] = []

        return CommuteRoute(
            origin: origin,
            destination: destination,
            distanceKm: distanceKm,
            estimatedDurationMinutes: estimatedDurationMinutes,
            mode: mode,
            weatherHazards: weatherHazards
        )
    }

    func weatherImpact(on route: CommuteRoute) async -> CommuteWeatherImpact {
        var hazards: [String] = []
        var score = 100

        if route.distanceKm > 50 {
            hazards.append("Long commute (\(String(format: "%.1f", route.distanceKm)) km) — weather conditions may vary significantly along the route.")
            score -= 10
        }

        if route.mode.isWindSensitive {
            hazards.append("High wind sensitivity for \(route.mode.rawValue). Gusts could affect stability.")
            score -= 15
        }

        let bestWindow: String? = route.mode == .cycling || route.mode == .walking
            ? "Early morning or late afternoon to avoid peak heat"
            : nil

        return CommuteWeatherImpact(
            overallScore: max(0, score),
            hazardWarnings: hazards,
            bestDepartureWindow: bestWindow
        )
    }

    func commuteBriefing(home: SavedLocation, work: SavedLocation, mode: TravelMode) async -> CommuteBriefing {
        let isSameLocation = home.latitude == work.latitude && home.longitude == work.longitude

        if isSameLocation {
            return CommuteBriefing(
                summary: "Home and work are the same location. No commute needed.",
                weatherAtOrigin: "N/A",
                weatherAtDestination: "N/A",
                routeHazards: [],
                recommendation: "Enjoy your day!"
            )
        }

        let route = try? await calculateCommute(from: home, to: work, mode: mode)
        let impact: CommuteWeatherImpact
        if let route = route {
            impact = await weatherImpact(on: route)
        } else {
            impact = CommuteWeatherImpact(overallScore: 50, hazardWarnings: ["Unable to calculate route details."], bestDepartureWindow: nil)
        }

        let distanceStr = route.map { String(format: "%.1f km", $0.distanceKm) } ?? "unknown"
        let durationStr = route.map { "\($0.estimatedDurationMinutes) min" } ?? "unknown"

        let summary: String = {
            if impact.overallScore >= 80 {
                return "Good commute conditions for \(mode.rawValue). \(distanceStr), approximately \(durationStr)."
            } else if impact.overallScore >= 50 {
                return "Moderate commute conditions for \(mode.rawValue). \(distanceStr), approximately \(durationStr). Some weather factors to consider."
            } else {
                return "Challenging commute conditions for \(mode.rawValue). \(distanceStr), approximately \(durationStr). Check weather hazards."
            }
        }()

        let recommendation: String = {
            if impact.overallScore >= 80 {
                return "Optimal conditions — proceed as planned."
            } else if impact.overallScore >= 50 {
                if let window = impact.bestDepartureWindow {
                    return "Consider departing \(window.lowercased()) for a more comfortable commute."
                }
                return "Allow extra time and check conditions before leaving."
            } else {
                return "Consider alternative transport or delaying your commute until conditions improve."
            }
        }()

        return CommuteBriefing(
            summary: summary,
            weatherAtOrigin: "Weather at home — \(impact.overallScore >= 60 ? "favorable" : "suboptimal")",
            weatherAtDestination: "Weather at work — \(impact.overallScore >= 60 ? "favorable" : "suboptimal")",
            routeHazards: impact.hazardWarnings,
            recommendation: recommendation
        )
    }
}
