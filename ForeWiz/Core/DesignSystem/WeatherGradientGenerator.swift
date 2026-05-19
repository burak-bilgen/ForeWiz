import SwiftUI

// MARK: - Gradient Generator

/// Stateless helper that generates weather-responsive gradient configurations.
/// Extracted from WeatherGradientService private extensions for modularity.
enum WeatherGradientGenerator {

    // MARK: - Internal Types

    enum TimeOfDay {
        case dawn, day, dusk, night
    }

    enum WeatherState {
        case clear, cloudy, rainy, stormy, snowy, foggy, hot, cold
    }

    // MARK: - Resolution

    static func resolveTimeOfDay(isDaylight: Bool?, colorScheme: ColorScheme) -> TimeOfDay {
        guard let isDaylight else {
            return colorScheme == .dark ? .night : .day
        }
        return isDaylight ? .day : .night
    }

    static func resolveWeatherState(condition: String?, temperature: Double?) -> WeatherState {
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

    static func conditionFromSymbol(_ symbolName: String) -> String {
        let lower = symbolName.lowercased()
        if lower.contains("rain") { return "rain" }
        if lower.contains("snow") { return "snow" }
        if lower.contains("cloud") { return "cloudy" }
        if lower.contains("bolt") || lower.contains("storm") { return "storm" }
        if lower.contains("sun") || lower.contains("clear") { return "clear" }
        return "clear"
    }

    // MARK: - Primary Gradient

    static func primaryGradient(
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

    // MARK: - Secondary Gradient

    static func secondaryGradient(
        timeOfDay: TimeOfDay,
        weatherState: WeatherState,
        decision: OutdoorDecision?,
        colorScheme: ColorScheme
    ) -> LinearGradient? {
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

    // MARK: - Accent Color

    static func accentColor(weatherState: WeatherState, decision: OutdoorDecision?) -> Color {
        if let decision {
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

    // MARK: - Particle Effect

    static func particleEffect(weatherState: WeatherState, timeOfDay: TimeOfDay) -> ParticleEffect? {
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

    // MARK: - Animation Speed

    static func animationSpeed(weatherState: WeatherState) -> Double {
        switch weatherState {
        case .stormy: return 1.5
        case .rainy: return 1.2
        case .snowy: return 0.6
        default: return 1.0
        }
    }
}
