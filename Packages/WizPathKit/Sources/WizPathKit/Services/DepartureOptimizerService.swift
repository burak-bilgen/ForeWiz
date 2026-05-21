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
        for window in windows {
            let score = await scoreDepartureWindow(window: window, origin: origin, destination: destination, travelMode: travelMode)
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

    private func scoreDepartureWindow(window date: Date, origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, travelMode: TravelMode) async -> ScoredDepartureWindow {
        let weatherScore = await evaluateWeatherScore(at: date)
        let trafficScore = evaluateTrafficScore(at: date)
        let (climateScore, alerts) = await evaluateClimateScore(at: date, travelMode: travelMode)
        let totalScore = calculateTotalScore(weather: weatherScore, traffic: trafficScore, climate: climateScore)
        let recommendation = recommendAction(for: totalScore, alerts: alerts)
        return ScoredDepartureWindow(departureTime: date, weatherScore: weatherScore, trafficScore: trafficScore, climateScore: climateScore, totalScore: totalScore, alerts: alerts, recommendation: recommendation)
    }

    private func evaluateWeatherScore(at date: Date) async -> Int {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<9: return 75
        case 9..<12: return 80
        case 12..<15: return 70
        case 15..<18: return 75
        case 18..<21: return 70
        default: return 50
        }
    }

    private func evaluateTrafficScore(at date: Date) -> Int {
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
        let hour = Calendar.current.component(.hour, from: date)
        if hour >= 12 && hour <= 15 { return (70, []) }
        return (85, [])
    }

    private func calculateTotalScore(weather: Int, traffic: Int, climate: Int) -> Int {
        let weighted = (weather * 40 + traffic * 35 + climate * 25) / 100
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
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60; let mins = minutes % 60
        return "\(hours)h \(mins)m"
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
        case .optimal: return "Best Time"
        case .good: return "Good Time"
        case .moderate: return "Acceptable"
        case .caution: return "Use Caution"
        case .poor: return "Not Recommended"
        }
    }
}
