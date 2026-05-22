import Foundation
import CoreLocation

// MARK: - Departure Optimizer Service
@MainActor
public final class DepartureOptimizerService {
    public struct Configuration {
        public static let windowCount = 12
        public static let windowInterval: TimeInterval = 30 * 60
        public static let minimumWeatherScore = 60
        public static let rushHourMultiplier = 1.5
    }

    private let weatherRepository: WizPathWeatherSource
    private let climateService: WizPathClimateService

    public init(weatherRepository: WizPathWeatherSource, climateService: WizPathClimateService = .shared) {
        self.weatherRepository = weatherRepository
        self.climateService = climateService
    }

    public func findOptimalDepartureTime(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, travelMode: TravelMode, earliestDeparture: Date, latestDeparture: Date) async throws -> DepartureOptimizationResult {
        let windows = generateDepartureWindows(from: earliestDeparture, to: latestDeparture)
        var scoredWindows: [ScoredDepartureWindow] = []
        // Prefetch weather once for the origin area, reuse across all windows
        let weatherSnapshot: WizPathWeatherSnapshot?
        do {
            let coord = WizPathCoordinate(latitude: origin.latitude, longitude: origin.longitude)
            weatherSnapshot = try await weatherRepository.fetchWeather(for: coord)
        } catch {
            AppLogger.wizPath.error("Weather prefetch failed for departure optimization: \(error.localizedDescription)")
            weatherSnapshot = nil
        }
        for window in windows {
            let score = await scoreDepartureWindow(window: window, origin: origin, destination: destination, travelMode: travelMode, weatherSnapshot: weatherSnapshot)
            scoredWindows.append(score)
        }
        scoredWindows.sort { $0.totalScore > $1.totalScore }
        let bestWindow = scoredWindows.first ?? ScoredDepartureWindow(departureTime: earliestDeparture, weatherScore: 0, trafficScore: 0, climateScore: 0, totalScore: 0, alerts: [], recommendation: .poor)
        return DepartureOptimizationResult(bestDepartureTime: bestWindow.departureTime, scoredWindows: scoredWindows, totalWindowsEvaluated: windows.count)
    }

    private func generateDepartureWindows(from start: Date, to end: Date) -> [Date] {
        var windows: [Date] = []; var current = start
        while current <= end && windows.count < Configuration.windowCount {
            windows.append(current)
            current = current.addingTimeInterval(Configuration.windowInterval)
        }
        return windows
    }

    private func scoreDepartureWindow(window date: Date, origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, travelMode: TravelMode, weatherSnapshot: WizPathWeatherSnapshot?) async -> ScoredDepartureWindow {
        let weatherScore = await evaluateWeatherScore(at: date, weatherSnapshot: weatherSnapshot)
        let trafficScore = evaluateTrafficScore(at: date)
        let (climateScore, alerts) = await evaluateClimateScore(at: date, travelMode: travelMode)
        let totalScore = calculateTotalScore(weather: weatherScore, traffic: trafficScore, climate: climateScore, travelMode: travelMode)
        let recommendation = recommendAction(for: totalScore, alerts: alerts)
        return ScoredDepartureWindow(departureTime: date, weatherScore: weatherScore, trafficScore: trafficScore, climateScore: climateScore, totalScore: totalScore, alerts: alerts, recommendation: recommendation)
    }

    private func evaluateWeatherScore(at date: Date, weatherSnapshot: WizPathWeatherSnapshot?) async -> Int {
        guard let snapshot = weatherSnapshot else { return 50 }
        let targetHour = Calendar.current.component(.hour, from: date)
        // Find the hourly forecast closest to the target departure hour
        let hourly = snapshot.hourly.min(by: {
            abs(Calendar.current.component(.hour, from: $0.date) - targetHour) <
            abs(Calendar.current.component(.hour, from: $1.date) - targetHour)
        })
        guard let forecast = hourly else { return 50 }
        var score = 80
        // Reduce score for precipitation
        if let precip = forecast.precipitationChance, precip > 0.3 {
            score -= Int((precip - 0.3) * 60)
        }
        // Reduce score for extreme temperatures
        if forecast.temperatureCelsius > 35 { score -= 30 }
        else if forecast.temperatureCelsius > 30 { score -= 15 }
        else if forecast.temperatureCelsius < 0 { score -= 25 }
        else if forecast.temperatureCelsius < 5 { score -= 10 }
        // Reduce score for high winds
        if let wind = forecast.windSpeedKph, wind > 40 { score -= 25 }
        else if let wind = forecast.windSpeedKph, wind > 25 { score -= 10 }
        // Bonus for clear conditions
        if let symbol = forecast.symbolName?.lowercased() {
            if symbol.contains("clear") || symbol.contains("sun") { score += 10 }
        }
        return max(0, min(100, score))
    }

    private func evaluateTrafficScore(at date: Date) -> Int {
        // Traffic score: rush-hour penalty for weekdays
        let hour = Calendar.current.component(.hour, from: date)
        let weekday = Calendar.current.component(.weekday, from: date)
        let isWeekday = weekday >= 2 && weekday <= 6
        guard isWeekday else { return 90 }
        switch hour {
        case 7..<9: return 50
        case 9..<12: return 85
        case 12..<14: return 75
        case 14..<17: return 80
        case 17..<19: return 45
        default: return 85
        }
    }

    private func evaluateClimateScore(at date: Date, travelMode: TravelMode) async -> (score: Int, alerts: [ClimateAlert]) {
        // Climate score: based on time-of-day heat risk + mode
        let hour = Calendar.current.component(.hour, from: date)
        var score = 85
        var alerts: [ClimateAlert] = []
        // Midday heat penalty for walking/cycling
        if (travelMode == .walking || travelMode == .cycling) && hour >= 11 && hour <= 15 {
            score -= 20
            alerts.append(ClimateAlert(
                type: .heatStrokeRisk,
                severity: .medium,
                title: WizPathKitL10n.text("climate_heat_stroke_title"),
                message: WizPathKitL10n.formatted("climate_heat_stroke_message", 32),
                eta: date,
                recommendation: WizPathKitL10n.text("climate_heat_stroke_recommendation")
            ))
        }
        // Cycling-specific: wind penalty
        if travelMode == .cycling {
            // Assume average wind of 20km/h if we don't have real data here
            // Real wind data is evaluated in the weather score; this is a time-of-day heuristic
            if hour >= 10 && hour <= 16 {
                score -= 10 // Warmer hours tend to have stronger thermal winds
            }
            // Early morning is safest for cycling (less wind, less traffic)
            if hour >= 5 && hour <= 8 {
                score += 10
            }
        }
        // Night driving: reduced visibility penalty
        if hour < 6 || hour >= 21 {
            if travelMode == .cycling {
                score -= 25 // Cycling at night is extra dangerous
            } else {
                score -= 10
            }
        }
        return (max(0, min(100, score)), alerts)
    }

    private func calculateTotalScore(weather: Int, traffic: Int, climate: Int, travelMode: TravelMode = .car) -> Int {
        // Cycling weights wind and climate more heavily
        let weatherWeight: Int
        let trafficWeight: Int
        let climateWeight: Int
        if travelMode == .cycling {
            weatherWeight = 50  // Weather (esp. wind) matters more for cyclists
            trafficWeight = 20  // Traffic matters less
            climateWeight = 30  // Climate (heat, visibility) matters more
        } else {
            weatherWeight = 40
            trafficWeight = 35
            climateWeight = 25
        }
        let weighted = (weather * weatherWeight + traffic * trafficWeight + climate * climateWeight) / 100
        return max(0, min(100, weighted))
    }

    private func recommendAction(for score: Int, alerts: [ClimateAlert]) -> DepartureRecommendation {
        if !alerts.isEmpty { return .caution }
        switch score {
        case 80...: return .optimal
        case 60..<80: return .good
        case 40..<60: return .moderate
        default: return .poor
        }
    }
}

// MARK: - Supporting Types

public struct DepartureOptimizationResult: Sendable {
    public let bestDepartureTime: Date
    public let scoredWindows: [ScoredDepartureWindow]
    public let totalWindowsEvaluated: Int

    public init(bestDepartureTime: Date, scoredWindows: [ScoredDepartureWindow], totalWindowsEvaluated: Int) {
        self.bestDepartureTime = bestDepartureTime; self.scoredWindows = scoredWindows; self.totalWindowsEvaluated = totalWindowsEvaluated
    }

    public var formattedBestTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: bestDepartureTime)
    }

    public var timeUntilBestDeparture: TimeInterval { max(0, bestDepartureTime.timeIntervalSinceNow) }

    public var formattedTimeUntil: String {
        let minutes = Int(timeUntilBestDeparture) / 60
        if minutes < 60 { return WizPathKitL10n.formatted("departure_min_format", minutes) }
        let hours = minutes / 60; let mins = minutes % 60
        return WizPathKitL10n.formatted("departure_hours_minutes_format", hours, mins)
    }
}

public struct ScoredDepartureWindow: Sendable {
    public let departureTime: Date
    public let weatherScore: Int
    public let trafficScore: Int
    public let climateScore: Int
    public let totalScore: Int
    public let alerts: [ClimateAlert]
    public let recommendation: DepartureRecommendation

    public init(departureTime: Date, weatherScore: Int, trafficScore: Int, climateScore: Int, totalScore: Int, alerts: [ClimateAlert], recommendation: DepartureRecommendation) {
        self.departureTime = departureTime; self.weatherScore = weatherScore; self.trafficScore = trafficScore; self.climateScore = climateScore; self.totalScore = totalScore; self.alerts = alerts; self.recommendation = recommendation
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: departureTime)
    }
}

public enum DepartureRecommendation: String, Sendable {
    case optimal = "optimal"
    case good = "good"
    case moderate = "moderate"
    case caution = "caution"
    case poor = "poor"

    public var colorHex: String {
        switch self {
        case .optimal: return "#34C759"
        case .good: return "#30D158"
        case .moderate: return "#FFCC00"
        case .caution: return "#FF9500"
        case .poor: return "#FF3B30"
        }
    }

    public var displayText: String {
        switch self {
        case .optimal: return WizPathKitL10n.text("departure_rec_optimal")
        case .good: return WizPathKitL10n.text("departure_rec_good")
        case .moderate: return WizPathKitL10n.text("departure_rec_moderate")
        case .caution: return WizPathKitL10n.text("departure_rec_caution")
        case .poor: return WizPathKitL10n.text("departure_rec_poor")
        }
    }
}
