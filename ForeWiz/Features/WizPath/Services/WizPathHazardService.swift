import Foundation
import CoreLocation
import MapKit
import OSLog

// MARK: - Hazard Detection Service
@MainActor
final class WizPathHazardService {
    static let shared = WizPathHazardService()
    
    // MARK: - Configuration
    struct Thresholds {
        // Crosswind thresholds (km/h)
        static let crosswindWarning: Double = 25
        static let crosswindDanger: Double = 40
        static let crosswindCritical: Double = 60
        
        // Sun glare thresholds
        static let glareWarning: Double = 0.7 // 70% of sun in eyes
        static let glareDanger: Double = 0.85 // 85% of sun in eyes
        
        // Sun position tolerance (degrees from directly ahead/behind)
        static let glareAngleTolerance: Double = 30
    }
    
    private init() {}
    
    // MARK: - Main Detection Method
    
    func detectHazards(along route: WizPathRoute) -> [EnvironmentalHazard] {
        var hazards: [EnvironmentalHazard] = []
        
        // Detect crosswinds
        let crosswinds = detectCrosswinds(along: route)
        hazards.append(contentsOf: crosswinds)
        
        // Detect sun glare
        let sunGlares = detectSunGlare(along: route)
        hazards.append(contentsOf: sunGlares)
        
        // Detect weather-based hazards from segments
        let weatherHazards = detectWeatherHazards(along: route)
        hazards.append(contentsOf: weatherHazards)
        
        // Sort by severity (critical first), then by time
        return hazards.sorted { lhs, rhs in
            if lhs.severity != rhs.severity {
                let severityOrder: [HazardSeverity: Int] = [
                    .critical: 0, .high: 1, .moderate: 2, .low: 3
                ]
                return (severityOrder[lhs.severity] ?? 4) < (severityOrder[rhs.severity] ?? 4)
            }
            return lhs.etaAtLocation < rhs.etaAtLocation
        }
    }
    
    // MARK: - Crosswind Detection
    
    private func detectCrosswinds(along route: WizPathRoute) -> [EnvironmentalHazard] {
        var hazards: [EnvironmentalHazard] = []
        let segments = route.segments
        
        guard segments.count > 1 else { return [] }
        
        for i in 1..<segments.count {
            let segment = segments[i]
            let previousSegment = segments[i-1]
            
            guard let weather = segment.weather else { continue }
            
            // Check wind speed threshold
            let windSpeed = weather.windSpeed
            
            if windSpeed < Thresholds.crosswindWarning {
                continue // Not significant
            }
            
            // Calculate route heading at this segment
            let heading = calculateHeading(
                from: previousSegment.coordinate,
                to: segment.coordinate
            )
            
            // Simulate wind direction (in real implementation, this comes from weather API)
            // For now, assume wind can come from any direction and check worst case
            let crosswindComponent = calculateCrosswindComponent(
                windSpeed: windSpeed,
                routeHeading: heading
            )
            
            // Determine severity
            let severity: HazardSeverity
            if crosswindComponent >= Thresholds.crosswindCritical {
                severity = .critical
            } else if crosswindComponent >= Thresholds.crosswindDanger {
                severity = .high
            } else if crosswindComponent >= Thresholds.crosswindWarning {
                severity = .moderate
            } else {
                continue
            }
            
            let hazard = EnvironmentalHazard(
                id: UUID(),
                type: .crosswind,
                coordinate: segment.coordinate,
                routeSegmentIndex: i,
                severity: severity,
                details: L10n.formatted("hazard_crosswind_details", Int(crosswindComponent)),
                recommendation: getCrosswindRecommendation(severity: severity, mode: route.travelMode),
                etaAtLocation: segment.estimatedArrival
            )
            
            hazards.append(hazard)
        }
        
        return hazards
    }
    
    private func calculateCrosswindComponent(windSpeed: Double, routeHeading: Double) -> Double {
        // Simulate worst-case crosswind (wind perpendicular to route)
        // In production, use actual wind direction from weather API
        // For demo, assume wind can be up to 90° from route heading
        let crosswindFactor = 0.7 // Assume 70% crosswind component
        return windSpeed * crosswindFactor
    }
    
    private func getCrosswindRecommendation(severity: HazardSeverity, mode: TravelMode) -> String {
        switch (severity, mode) {
        case (.critical, _):
            return L10n.text("hazard_crosswind_critical_rec")
        case (.high, .car):
            return L10n.text("hazard_crosswind_high_car_rec")
        case (.high, .walking):
            return L10n.text("hazard_crosswind_high_walk_rec")
        case (.moderate, _):
            return L10n.text("hazard_crosswind_moderate_rec")
        default:
            return L10n.text("hazard_crosswind_default_rec")
        }
    }
    
    // MARK: - Sun Glare Detection
    
    private func detectSunGlare(along route: WizPathRoute) -> [EnvironmentalHazard] {
        var hazards: [EnvironmentalHazard] = []
        let segments = route.segments
        
        guard segments.count > 1 else { return [] }
        
        // Calculate sun position for each segment's ETA
        for i in 1..<segments.count {
            let segment = segments[i]
            let previousSegment = segments[i-1]
            
            let eta = segment.estimatedArrival
            let coordinate = segment.coordinate
            
            // Get sun position at this time and location
            let sunPosition = calculateSunPosition(date: eta, coordinate: coordinate)
            
            // Calculate route heading
            let heading = calculateHeading(
                from: previousSegment.coordinate,
                to: segment.coordinate
            )
            
            // Check if sun is in driver's eyes
            let glareIntensity = calculateGlareIntensity(
                sunPosition: sunPosition,
                routeHeading: heading,
                weather: segment.weather
            )
            
            // Determine if significant glare
            guard glareIntensity > Thresholds.glareWarning else { continue }
            
            // Determine severity
            let severity: HazardSeverity
            if glareIntensity > Thresholds.glareDanger {
                severity = .high
            } else {
                severity = .moderate
            }
            
            let hazard = EnvironmentalHazard(
                id: UUID(),
                type: .sunGlare,
                coordinate: segment.coordinate,
                routeSegmentIndex: i,
                severity: severity,
                details: L10n.formatted("hazard_sunglare_details", Int(glareIntensity * 100)),
                recommendation: L10n.text("hazard_sunglare_rec"),
                etaAtLocation: segment.estimatedArrival
            )
            
            hazards.append(hazard)
        }
        
        return hazards
    }
    
    // MARK: - Weather-Based Hazards
    
    private func detectWeatherHazards(along route: WizPathRoute) -> [EnvironmentalHazard] {
        var hazards: [EnvironmentalHazard] = []
        
        for (index, segment) in route.segments.enumerated() {
            guard let weather = segment.weather else { continue }
            
            // Check for severe weather conditions
            let hazardType: HazardType?
            let severity: HazardSeverity
            
            switch weather.condition {
            case .thunderstorm:
                hazardType = .thunderstorm
                severity = .high
            case .heavyRain:
                hazardType = .heavyRain
                severity = weather.precipitationChance > 0.7 ? .high : .moderate
            case .snow:
                hazardType = .snow
                severity = weather.temperature < -5 ? .critical : .high
            case .fog:
                hazardType = .fog
                if let visibility = weather.visibility, visibility < 0.5 {
                    severity = .critical // < 500m visibility
                } else if let visibility = weather.visibility, visibility < 1 {
                    severity = .high // < 1km visibility
                } else {
                    severity = .moderate
                }
            default:
                hazardType = nil
                severity = .low
            }
            
            if let type = hazardType {
                let hazard = EnvironmentalHazard(
                    id: UUID(),
                    type: type,
                    coordinate: segment.coordinate,
                    routeSegmentIndex: index,
                    severity: severity,
                    details: L10n.text("hazard_weather_details_\(type.rawValue)"),
                    recommendation: L10n.text("hazard_weather_rec_\(type.rawValue)"),
                    etaAtLocation: segment.estimatedArrival
                )
                hazards.append(hazard)
            }
            
            // Check for icy conditions
            if weather.temperature < 2 && weather.precipitationChance > 0.3 {
                let iceHazard = EnvironmentalHazard(
                    id: UUID(),
                    type: .ice,
                    coordinate: segment.coordinate,
                    routeSegmentIndex: index,
                    severity: weather.temperature < -2 ? .high : .moderate,
                    details: L10n.formatted("hazard_ice_details", Int(weather.temperature)),
                    recommendation: L10n.text("hazard_ice_rec"),
                    etaAtLocation: segment.estimatedArrival
                )
                hazards.append(iceHazard)
            }
        }
        
        return hazards
    }
    
    // MARK: - Calculation Helpers
    
    private func calculateHeading(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        
        let x = sin(dLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let heading = atan2(x, y) * 180 / .pi
        
        return (heading + 360).truncatingRemainder(dividingBy: 360)
    }
    
    private func calculateSunPosition(date: Date, coordinate: CLLocationCoordinate2D) -> SunPosition {
        // Simplified sun position calculation
        // In production, use a proper astronomical library
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // Simplified: sun rises in east (90°), sets in west (270°)
        // At noon (12:00), sun is south (180°)
        var azimuth: Double
        var elevation: Double
        
        if hour >= 6 && hour <= 18 {
            // Daytime
            let progress = Double(hour - 6) / 12.0
            azimuth = 90 + (progress * 180) // East (90) to West (270)
            elevation = 90 - abs(Double(hour - 12)) * 15 // Peak at noon
        } else {
            // Night
            azimuth = 180
            elevation = -18 // Below horizon
        }
        
        return SunPosition(azimuth: azimuth, elevation: elevation)
    }
    
    private func calculateGlareIntensity(
        sunPosition: SunPosition,
        routeHeading: Double,
        weather: SegmentWeather?
    ) -> Double {
        // Sun must be above horizon
        guard sunPosition.elevation > 5 else { return 0 }
        
        // Check if sun is in front of driver
        // Sun azimuth should be close to route heading (± tolerance)
        let sunAzimuth = sunPosition.azimuth
        let headingDiff = abs(sunAzimuth - routeHeading)
        let normalizedDiff = min(headingDiff, 360 - headingDiff)
        
        // Check if sun is within glare angle
        guard normalizedDiff < Thresholds.glareAngleTolerance else { return 0 }
        
        // Calculate intensity based on:
        // 1. How directly sun is in eyes
        let alignmentFactor = 1 - (normalizedDiff / Thresholds.glareAngleTolerance)
        
        // 2. Cloud cover (clear skies = worse glare)
        let cloudFactor: Double
        switch weather?.condition {
        case .clear, .partlyCloudy: cloudFactor = 1.0
        case .cloudy: cloudFactor = 0.5
        case .fog: cloudFactor = 0.3
        default: cloudFactor = 0.7
        }
        
        // 3. Elevation (lower sun = worse glare)
        let elevationFactor = max(0, 1 - (sunPosition.elevation / 45))
        
        return alignmentFactor * cloudFactor * elevationFactor
    }
}

// MARK: - Sun Position
struct SunPosition: Sendable {
    let azimuth: Double // Degrees from north (0-360)
    let elevation: Double // Degrees above horizon (-90 to 90)
}
