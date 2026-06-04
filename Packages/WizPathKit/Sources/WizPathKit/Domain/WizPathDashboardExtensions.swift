import SwiftUI
import CoreLocation

// MARK: - Route Risk Color (via AppTheme)

extension WizPathRoute {
    public func journeyHUDData(smartStops: [SmartStop] = []) -> JourneyHUDData {
        let hazards = generateEnvironmentalHazards()
        let safeStops = smartStops.filter { $0.isRecommended }
        let nextSafeStop = safeStops.min(by: { $0.etaArrival < $1.etaArrival })
        return JourneyHUDData(totalDuration: totalDuration, totalDistance: totalDistance, hazardCount: hazards.count, safeStops: safeStops.count, safetyScore: overallRisk.safetyScore, activeHazards: hazards, nextSafeStop: nextSafeStop)
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
                details = WizPathKitL10n.formatted("wizpath_hazard_thunderstorm_detail", Int(weather.windSpeed))
                recommendation = WizPathKitL10n.text("wizpath_hazard_thunderstorm_rec")
            case .heavyRain:
                hazardType = .heavyRain
                details = WizPathKitL10n.formatted("wizpath_hazard_heavyrain_detail", Int(weather.precipitationChance * 100))
                recommendation = WizPathKitL10n.text("wizpath_hazard_heavyrain_rec")
            case .fog:
                hazardType = .fog
                details = WizPathKitL10n.formatted("wizpath_hazard_fog_detail", Int(weather.visibility ?? 0))
                recommendation = WizPathKitL10n.text("wizpath_hazard_fog_rec")
            case .snow, .sleet:
                hazardType = .snow
                details = WizPathKitL10n.formatted("wizpath_hazard_snow_detail", Int(weather.temperature))
                recommendation = WizPathKitL10n.text("wizpath_hazard_snow_rec")
            default:
                if weather.windSpeed > 50 {
                    hazardType = .crosswind
                    details = WizPathKitL10n.formatted("wizpath_hazard_wind_detail", Int(weather.windSpeed))
                    recommendation = WizPathKitL10n.text("wizpath_hazard_wind_rec")
                } else if weather.temperature <= 0 && weather.condition == .clear {
                    hazardType = .ice
                    details = WizPathKitL10n.formatted("wizpath_hazard_ice_detail", Int(weather.temperature))
                    recommendation = WizPathKitL10n.text("wizpath_hazard_ice_rec")
                } else {
                    hazardType = nil; details = ""; recommendation = ""
                }
            }
            if let type = hazardType {
                let severity: HazardSeverity
                switch weather.severity {
                case .severe: severity = .critical
                case .caution: severity = .high
                default: severity = .moderate
                }
                hazards.append(EnvironmentalHazard(id: UUID(), type: type, coordinate: segment.coordinate, routeSegmentIndex: index, severity: severity, details: details, recommendation: recommendation, etaAtLocation: segment.estimatedArrival))
            }
        }
        return hazards
    }
}

extension RouteRisk {
    public var safetyScore: Int {
        switch self {
        case .good: return 85
        case .caution: return 60
        case .severe: return 30
        }
    }
}
