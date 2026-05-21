import Foundation
import CoreLocation

// MARK: - Departure Optimizer Service
/// Finds the optimal departure time based on weather conditions and traffic patterns.
/// Evaluates multiple departure windows and scores them to recommend the best time to leave.
@MainActor
final class DepartureOptimizerService {
    
    // MARK: - Configuration
    
    struct Configuration {
        /// Number of departure windows to evaluate
        static let windowCount = 12
        /// Interval between windows (30 minutes)
        static let windowInterval: TimeInterval = 30 * 60
        /// Minimum acceptable weather score (0-100)
        static let minimumWeatherScore = 60
        /// Traffic multiplier for rush hours
        static let rushHourMultiplier = 1.5
    }
    
    // MARK: - Dependencies
    
    private let weatherRepository: WeatherRepository
    private let climateService: WizPathClimateService
    
    init(
        weatherRepository: WeatherRepository,
        climateService: WizPathClimateService = .shared
    ) {
        self.weatherRepository = weatherRepository
        self.climateService = climateService
    }
    
    // MARK: - Optimization
    
    /// Find the optimal departure time for a route
    func findOptimalDepartureTime(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        travelMode: TravelMode,
        earliestDeparture: Date,
        latestDeparture: Date
    ) async throws -> DepartureOptimizationResult {
        let windows = generateDepartureWindows(
            from: earliestDeparture,
            to: latestDeparture
        )
        
        var scoredWindows: [ScoredDepartureWindow] = []
        
        for window in windows {
            let score = await scoreDepartureWindow(
                window: window,
                origin: origin,
                destination: destination,
                travelMode: travelMode
            )
            scoredWindows.append(score)
        }
        
        scoredWindows.sort { $0.totalScore > $1.totalScore }
        
        let bestWindow = scoredWindows.first ?? ScoredDepartureWindow(
            departureTime: earliestDeparture,
            weatherScore: 0,
            trafficScore: 0,
            climateScore: 0,
            totalScore: 0,
            alerts: [],
            recommendation: .poor
        )
        
        return DepartureOptimizationResult(
            bestDepartureTime: bestWindow.departureTime,
            scoredWindows: scoredWindows,
            totalWindowsEvaluated: windows.count
        )
    }
    
    // MARK: - Window Generation
    
    private func generateDepartureWindows(
        from start: Date,
        to end: Date
    ) -> [Date] {
        var windows: [Date] = []
        var current = start
        
        while current <= end && windows.count < Configuration.windowCount {
            windows.append(current)
            current = current.addingTimeInterval(Configuration.windowInterval)
        }
        
        return windows
    }
    
    // MARK: - Scoring
    
    private func scoreDepartureWindow(
        window date: Date,
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        travelMode: TravelMode
    ) async -> ScoredDepartureWindow {
        let weatherScore = await evaluateWeatherScore(at: date)
        let trafficScore = evaluateTrafficScore(at: date)
        let (climateScore, alerts) = await evaluateClimateScore(at: date, travelMode: travelMode)
        
        let totalScore = calculateTotalScore(
            weather: weatherScore,
            traffic: trafficScore,
            climate: climateScore
        )
        
        let recommendation = recommendAction(for: totalScore, alerts: alerts)
        
        return ScoredDepartureWindow(
            departureTime: date,
            weatherScore: weatherScore,
            trafficScore: trafficScore,
            climateScore: climateScore,
            totalScore: totalScore,
            alerts: alerts,
            recommendation: recommendation
        )
    }
    
    private func evaluateWeatherScore(at date: Date) async -> Int {
        let hour = Calendar.current.component(.hour, from: date)
        
        // Simple time-based weather estimation
        // In production, this would use cached hourly forecast data
        switch hour {
        case 6..<9: return 75  // Morning - generally good
        case 9..<12: return 80 // Late morning - best
        case 12..<15: return 70 // Midday - can be hot
        case 15..<18: return 75 // Afternoon - good
        case 18..<21: return 70 // Evening - cooling down
        default: return 50     // Night - limited visibility
        }
    }
    
    private func evaluateTrafficScore(at date: Date) -> Int {
        let hour = Calendar.current.component(.hour, from: date)
        let weekday = Calendar.current.component(.weekday, from: date)
        let isWeekday = weekday >= 2 && weekday <= 6
        
        guard isWeekday else { return 90 } // Weekend - low traffic
        
        switch hour {
        case 7..<9: return 50   // Morning rush
        case 9..<12: return 85  // Mid-morning - good
        case 12..<14: return 75 // Lunch - moderate
        case 14..<17: return 80 // Afternoon - good
        case 17..<19: return 45 // Evening rush - worst
        default: return 85      // Off-peak
        }
    }
    
    private func evaluateClimateScore(
        at date: Date,
        travelMode: TravelMode
    ) async -> (score: Int, alerts: [ClimateAlert]) {
        // In production, this would analyze actual weather data
        // For now, return a reasonable estimate
        let hour = Calendar.current.component(.hour, from: date)
        
        if hour >= 12 && hour <= 15 {
            // Midday heat risk
            return (70, [])
        }
        
        return (85, [])
    }
    
    private func calculateTotalScore(
        weather: Int,
        traffic: Int,
        climate: Int
    ) -> Int {
        // Weighted average: weather 40%, traffic 35%, climate 25%
        let weighted = (weather * 40 + traffic * 35 + climate * 25) / 100
        return max(0, min(100, weighted))
    }
    
    private func recommendAction(
        for score: Int,
        alerts: [ClimateAlert]
    ) -> DepartureRecommendation {
        if !alerts.isEmpty {
            return .caution
        }
        
        switch score {
        case 80...: return .optimal
        case 60..<80: return .good
        case 40..<60: return .moderate
        default: return .poor
        }
    }
}

// MARK: - Supporting Types

struct DepartureOptimizationResult {
    let bestDepartureTime: Date
    let scoredWindows: [ScoredDepartureWindow]
    let totalWindowsEvaluated: Int
    
    var formattedBestTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: bestDepartureTime)
    }
    
    var timeUntilBestDeparture: TimeInterval {
        max(0, bestDepartureTime.timeIntervalSinceNow)
    }
    
    var formattedTimeUntil: String {
        let minutes = Int(timeUntilBestDeparture) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

struct ScoredDepartureWindow {
    let departureTime: Date
    let weatherScore: Int
    let trafficScore: Int
    let climateScore: Int
    let totalScore: Int
    let alerts: [ClimateAlert]
    let recommendation: DepartureRecommendation
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: departureTime)
    }
}

enum DepartureRecommendation: String {
    case optimal = "optimal"
    case good = "good"
    case moderate = "moderate"
    case caution = "caution"
    case poor = "poor"
    
    var colorHex: String {
        switch self {
        case .optimal: return "#34C759"
        case .good: return "#30D158"
        case .moderate: return "#FFCC00"
        case .caution: return "#FF9500"
        case .poor: return "#FF3B30"
        }
    }
    
    var displayText: String {
        switch self {
        case .optimal: return "Best Time"
        case .good: return "Good Time"
        case .moderate: return "Acceptable"
        case .caution: return "Use Caution"
        case .poor: return "Not Recommended"
        }
    }
}
