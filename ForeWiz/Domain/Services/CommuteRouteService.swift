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
            let distStr = String(format: "%.1f km", route.distanceKm)
            hazards.append(L10n.formatted("commute_hazard_long", distStr))
            score -= 10
        }

        if route.mode.isWindSensitive {
            hazards.append(L10n.text("commute_hazard_wind"))
            score -= 15
        }

        let bestWindow: String? = route.mode == .cycling || route.mode == .walking
            ? L10n.text("commute_best_window")
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
                summary: L10n.text("commute_same_location"),
                weatherAtOrigin: "N/A",
                weatherAtDestination: "N/A",
                routeHazards: [],
                recommendation: L10n.text("commute_same_location")
            )
        }

        let route = try? await calculateCommute(from: home, to: work, mode: mode)
        let impact: CommuteWeatherImpact
        if let route = route {
            impact = await weatherImpact(on: route)
        } else {
            impact = CommuteWeatherImpact(overallScore: 50, hazardWarnings: [L10n.text("commute_hazard_unable")], bestDepartureWindow: nil)
        }

        let distanceStr = route.map { String(format: "%.1f km", $0.distanceKm) } ?? "? km"
        let durationCompact = route.map { L10n.formatted("departure_min_format", $0.estimatedDurationMinutes) } ?? "?"

        let summary: String = {
            if impact.overallScore >= 80 {
                return L10n.formatted("commute_summary_good", distanceStr, durationCompact)
            } else if impact.overallScore >= 50 {
                return L10n.formatted("commute_summary_moderate", distanceStr, durationCompact)
            } else {
                return L10n.formatted("commute_summary_poor", distanceStr, durationCompact)
            }
        }()

        let recommendation: String = {
            if impact.overallScore >= 80 {
                return L10n.text("commute_rec_optimal")
            } else if impact.overallScore >= 50 {
                if let window = impact.bestDepartureWindow {
                    return L10n.formatted("commute_rec_caution", window.lowercased())
                }
                return L10n.text("commute_rec_extra_time")
            } else {
                return L10n.text("commute_rec_alternative")
            }
        }()

        let weatherQualifier = impact.overallScore >= 60
            ? L10n.text("commute_weather_favorable")
            : L10n.text("commute_weather_suboptimal")

        return CommuteBriefing(
            summary: summary,
            weatherAtOrigin: weatherQualifier,
            weatherAtDestination: weatherQualifier,
            routeHazards: impact.hazardWarnings,
            recommendation: recommendation
        )
    }
}
