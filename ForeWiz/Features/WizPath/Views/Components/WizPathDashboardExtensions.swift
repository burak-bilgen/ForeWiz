import SwiftUI
import CoreLocation

// MARK: - Route Risk Color

extension Color {
    static func routeRiskColor(_ risk: RouteRisk) -> Color {
        switch risk {
        case .good: return Color.success
        case .caution: return Color.warning
        case .severe: return Color.danger
        }
    }
}

// MARK: - WizPathSegment + ETA Short Display

extension WizPathSegment {
    var etaShortDisplay: String {
        SharedFormatters.shortTime.string(from: estimatedArrival)
    }
}

// MARK: - Journey HUD Data

extension WizPathRoute {
    var journeyHUDData: JourneyHUDData {
        let hazards = generateEnvironmentalHazards()
        return JourneyHUDData(
            totalDuration: totalDuration,
            totalDistance: totalDistance,
            hazardCount: hazards.count,
            safeStops: 0,
            safetyScore: overallRisk.safetyScore,
            activeHazards: hazards,
            nextSafeStop: nil
        )
    }

    private func generateEnvironmentalHazards() -> [EnvironmentalHazard] {
        var hazards: [EnvironmentalHazard] = []
        for (index, segment) in segments.enumerated() {
            guard let weather = segment.weather else { continue }
            let hazardType: HazardType?
            let details: String
            let recommendation: String

            switch weather.condition {
            case .thunderstorm:
                hazardType = .thunderstorm
                details = L10n.formatted("wizpath_hazard_thunderstorm_detail", Int(weather.windSpeed))
                recommendation = L10n.text("wizpath_hazard_thunderstorm_rec")
            case .heavyRain:
                hazardType = .heavyRain
                details = L10n.formatted("wizpath_hazard_heavyrain_detail", Int(weather.precipitationChance * 100))
                recommendation = L10n.text("wizpath_hazard_heavyrain_rec")
            case .fog:
                hazardType = .fog
                details = L10n.formatted("wizpath_hazard_fog_detail", Int(weather.visibility ?? 0))
                recommendation = L10n.text("wizpath_hazard_fog_rec")
            case .snow, .sleet:
                hazardType = .snow
                details = L10n.formatted("wizpath_hazard_snow_detail", Int(weather.temperature))
                recommendation = L10n.text("wizpath_hazard_snow_rec")
            default:
                if weather.windSpeed > 50 {
                    hazardType = .crosswind
                    details = L10n.formatted("wizpath_hazard_wind_detail", Int(weather.windSpeed))
                    recommendation = L10n.text("wizpath_hazard_wind_rec")
                } else if weather.temperature <= 0 && weather.condition == .clear {
                    hazardType = .ice
                    details = L10n.formatted("wizpath_hazard_ice_detail", Int(weather.temperature))
                    recommendation = L10n.text("wizpath_hazard_ice_rec")
                } else {
                    hazardType = nil
                    details = ""
                    recommendation = ""
                }
            }

            if let type = hazardType {
                let severity: HazardSeverity
                switch weather.severity {
                case .severe: severity = .critical
                case .caution: severity = .high
                default: severity = .moderate
                }
                hazards.append(EnvironmentalHazard(
                    id: UUID(),
                    type: type,
                    coordinate: segment.coordinate,
                    routeSegmentIndex: index,
                    severity: severity,
                    details: details,
                    recommendation: recommendation,
                    etaAtLocation: segment.estimatedArrival
                ))
            }
        }
        return hazards
    }
}

// MARK: - Route Risk Safety Score

extension RouteRisk {
    var safetyScore: Int {
        switch self {
        case .good: return 85
        case .caution: return 60
        case .severe: return 30
        }
    }
}
