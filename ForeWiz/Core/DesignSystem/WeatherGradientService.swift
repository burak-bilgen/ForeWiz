import SwiftUI
import Combine

/// A service that generates context-aware gradient backgrounds based on
/// weather conditions, time of day, and outdoor decision state.
///
/// This creates the "delight" factor for Apple Design Award consideration by
/// providing fluid, weather-responsive visual atmospheres.
@MainActor
final class WeatherGradientService: ObservableObject {
    static let shared = WeatherGradientService()
    
    private init() {}
    
    /// Generates a gradient set for the current weather context.
    ///
    /// - Parameters:
    ///   - condition: Weather condition code
    ///   - isDaylight: Whether it's currently daytime
    ///   - temperature: Temperature in Celsius
    ///   - decision: Outdoor decision state
    ///   - colorScheme: System color scheme preference
    /// - Returns: A complete gradient configuration
    func gradientFor(
        condition: String?,
        isDaylight: Bool?,
        temperature: Double?,
        decision: OutdoorDecision?,
        colorScheme: ColorScheme
    ) -> WeatherGradientSet {
        let timeOfDay = resolveTimeOfDay(isDaylight: isDaylight, colorScheme: colorScheme)
        let weatherState = resolveWeatherState(condition: condition, temperature: temperature)
        
        return WeatherGradientSet(
            primary: primaryGradient(timeOfDay: timeOfDay, weatherState: weatherState, colorScheme: colorScheme),
            secondary: secondaryGradient(timeOfDay: timeOfDay, weatherState: weatherState, decision: decision, colorScheme: colorScheme),
            accent: accentColor(weatherState: weatherState, decision: decision),
            particleEffect: particleEffect(weatherState: weatherState, timeOfDay: timeOfDay),
            animationSpeed: animationSpeed(weatherState: weatherState)
        )
    }
    
    /// Quick gradient for symbol names (backward compatibility).
    func gradientFor(symbolName: String, colorScheme: ColorScheme) -> LinearGradient {
        let condition = conditionFromSymbol(symbolName)
        let set = gradientFor(
            condition: condition,
            isDaylight: !symbolName.contains("moon"),
            temperature: nil,
            decision: nil,
            colorScheme: colorScheme
        )
        return set.primary
    }
}

// MARK: - Gradient Set

struct WeatherGradientSet {
    let primary: LinearGradient
    let secondary: LinearGradient?
    let accent: Color
    let particleEffect: ParticleEffect?
    let animationSpeed: Double
    
    static let `default` = WeatherGradientSet(
        primary: LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        ),
        secondary: nil,
        accent: .blue,
        particleEffect: nil,
        animationSpeed: 1.0
    )
}

enum ParticleEffect: Equatable {
    case rain(Intensity: Double)
    case snow(Intensity: Double)
    case clouds(Density: Double)
    case stars(Count: Int)
    case sunRays(Intensity: Double)
}

// MARK: - Private Resolution Logic

private extension WeatherGradientService {
    enum TimeOfDay {
        case dawn, day, dusk, night
    }
    
    enum WeatherState {
        case clear, cloudy, rainy, stormy, snowy, foggy, hot, cold
    }
    
    func resolveTimeOfDay(isDaylight: Bool?, colorScheme: ColorScheme) -> TimeOfDay {
        guard let isDaylight = isDaylight else {
            return colorScheme == .dark ? .night : .day
        }
        return isDaylight ? .day : .night
    }
    
    func resolveWeatherState(condition: String?, temperature: Double?) -> WeatherState {
        let conditionLower = condition?.lowercased() ?? ""
        
        if conditionLower.contains("thunder") || conditionLower.contains("storm") {
            return .stormy
        }
        if conditionLower.contains("rain") || conditionLower.contains("drizzle") {
            return .rainy
        }
        if conditionLower.contains("snow") || conditionLower.contains("sleet") {
            return .snowy
        }
        if conditionLower.contains("fog") || conditionLower.contains("haze") {
            return .foggy
        }
        if conditionLower.contains("cloud") {
            return .cloudy
        }
        if let temp = temperature {
            if temp > 30 { return .hot }
            if temp < 0 { return .cold }
        }
        
        return .clear
    }
    
    func conditionFromSymbol(_ symbolName: String) -> String {
        let lower = symbolName.lowercased()
        if lower.contains("rain") { return "rain" }
        if lower.contains("snow") { return "snow" }
        if lower.contains("cloud") { return "cloudy" }
        if lower.contains("bolt") || lower.contains("storm") { return "storm" }
        if lower.contains("sun") || lower.contains("clear") { return "clear" }
        return "clear"
    }
}

// MARK: - Gradient Generation

private extension WeatherGradientService {
    func primaryGradient(
        timeOfDay: TimeOfDay,
        weatherState: WeatherState,
        colorScheme: ColorScheme
    ) -> LinearGradient {
        switch (timeOfDay, weatherState, colorScheme) {
        // Day + Clear = Bright, cheerful
        case (.day, .clear, _):
            return LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.65, blue: 0.95),
                    Color(red: 0.45, green: 0.75, blue: 0.98),
                    Color(red: 0.98, green: 0.85, blue: 0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        // Night + Clear = Deep, starry
        case (.night, .clear, .dark), (.night, .clear, .light):
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    Color(red: 0.08, green: 0.12, blue: 0.22),
                    Color(red: 0.12, green: 0.15, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        // Rainy = Moody, cool
        case (_, .rainy, .dark):
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.18),
                    Color(red: 0.12, green: 0.18, blue: 0.25),
                    Color(red: 0.15, green: 0.22, blue: 0.30)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        case (_, .rainy, .light):
            return LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.72, blue: 0.82),
                    Color(red: 0.75, green: 0.82, blue: 0.90),
                    Color(red: 0.70, green: 0.78, blue: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        // Stormy = Dramatic, intense
        case (_, .stormy, .dark):
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.10),
                    Color(red: 0.15, green: 0.10, blue: 0.25),
                    Color(red: 0.20, green: 0.15, blue: 0.30)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        // Cloudy = Soft, diffused
        case (_, .cloudy, .dark):
            return LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.16),
                    Color(red: 0.15, green: 0.18, blue: 0.22),
                    Color(red: 0.12, green: 0.14, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        case (_, .cloudy, .light):
            return LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.85, blue: 0.88),
                    Color(red: 0.88, green: 0.90, blue: 0.92),
                    Color(red: 0.85, green: 0.87, blue: 0.90)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        // Snowy = Crisp, cold
        case (_, .snowy, .dark):
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.15, blue: 0.22),
                    Color(red: 0.18, green: 0.22, blue: 0.30),
                    Color(red: 0.15, green: 0.20, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        // Hot = Warm, intense
        case (_, .hot, _):
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.50, blue: 0.30),
                    Color(red: 0.98, green: 0.65, blue: 0.35),
                    Color(red: 0.90, green: 0.75, blue: 0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        // Cold = Icy, sharp
        case (_, .cold, _):
            return LinearGradient(
                colors: [
                    Color(red: 0.75, green: 0.85, blue: 0.95),
                    Color(red: 0.80, green: 0.88, blue: 0.98),
                    Color(red: 0.70, green: 0.78, blue: 0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        // Foggy = Muted, mysterious
        case (_, .foggy, .dark):
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.12),
                    Color(red: 0.12, green: 0.14, blue: 0.16),
                    Color(red: 0.10, green: 0.12, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        // Default fallback
        default:
            return colorScheme == .dark
                ? LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.14),
                        Color(red: 0.08, green: 0.12, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                : LinearGradient(
                    colors: [
                        Color(red: 0.88, green: 0.92, blue: 0.98),
                        Color(red: 0.92, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
        }
    }
    
    func secondaryGradient(
        timeOfDay: TimeOfDay,
        weatherState: WeatherState,
        decision: OutdoorDecision?,
        colorScheme: ColorScheme
    ) -> LinearGradient? {
        // Only show secondary gradient for dramatic weather or decisions
        guard decision != nil || [.stormy, .rainy, .hot].contains(weatherState) else {
            return nil
        }
        
        let decisionColor: Color
        switch decision {
        case .good: decisionColor = Color(red: 0.2, green: 0.7, blue: 0.4)
        case .moderate: decisionColor = Color(red: 0.35, green: 0.65, blue: 0.95)
        case .risky: decisionColor = Color(red: 0.95, green: 0.65, blue: 0.2)
        case .avoid: decisionColor = Color(red: 0.9, green: 0.25, blue: 0.3)
        case nil: decisionColor = .clear
        }
        
        return LinearGradient(
            colors: [
                decisionColor.opacity(0.15),
                decisionColor.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    func accentColor(weatherState: WeatherState, decision: OutdoorDecision?) -> Color {
        if let decision = decision {
            switch decision {
            case .good: return Color(red: 0.2, green: 0.7, blue: 0.4)
            case .moderate: return Color(red: 0.35, green: 0.65, blue: 0.95)
            case .risky: return Color(red: 0.95, green: 0.65, blue: 0.2)
            case .avoid: return Color(red: 0.9, green: 0.25, blue: 0.3)
            }
        }
        
        switch weatherState {
        case .clear: return Color(red: 0.98, green: 0.75, blue: 0.35)
        case .cloudy: return Color(red: 0.7, green: 0.75, blue: 0.85)
        case .rainy: return Color(red: 0.4, green: 0.65, blue: 0.9)
        case .stormy: return Color(red: 0.6, green: 0.5, blue: 0.8)
        case .snowy: return Color(red: 0.75, green: 0.85, blue: 0.95)
        case .hot: return Color(red: 0.95, green: 0.5, blue: 0.3)
        case .cold: return Color(red: 0.5, green: 0.8, blue: 0.95)
        case .foggy: return Color(red: 0.65, green: 0.7, blue: 0.75)
        }
    }
    
    func particleEffect(weatherState: WeatherState, timeOfDay: TimeOfDay) -> ParticleEffect? {
        switch weatherState {
        case .rainy:
            return .rain(Intensity: 0.6)
        case .stormy:
            return .rain(Intensity: 1.0)
        case .snowy:
            return .snow(Intensity: 0.7)
        case .clear where timeOfDay == .night:
            return .stars(Count: 50)
        case .clear where timeOfDay == .day:
            return .sunRays(Intensity: 0.4)
        default:
            return nil
        }
    }
    
    func animationSpeed(weatherState: WeatherState) -> Double {
        switch weatherState {
        case .stormy: return 1.5
        case .rainy: return 1.2
        case .snowy: return 0.6
        default: return 1.0
        }
    }
}

// MARK: - SwiftUI View Extension

struct WeatherAwareBackground: View {
    @ObservedObject private var service = WeatherGradientService.shared
    let condition: String?
    let isDaylight: Bool?
    let temperature: Double?
    let decision: OutdoorDecision?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let gradientSet = service.gradientFor(
            condition: condition,
            isDaylight: isDaylight,
            temperature: temperature,
            decision: decision,
            colorScheme: colorScheme
        )
        
        ZStack {
            gradientSet.primary
                .ignoresSafeArea()
            
            if let secondary = gradientSet.secondary {
                secondary
                    .ignoresSafeArea()
                    .opacity(0.5)
            }
        }
        .animation(.easeInOut(duration: 2.0), value: condition)
    }
}
