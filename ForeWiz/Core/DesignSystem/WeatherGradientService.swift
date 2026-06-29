import SwiftUI
import Combine

@MainActor
final class WeatherGradientService: ObservableObject {
    static let shared = WeatherGradientService()

    private init() {}

    func gradientFor(
        condition: String?,
        isDaylight: Bool?,
        temperature: Double?,
        decision: OutdoorDecision?,
        colorScheme: ColorScheme
    ) -> WeatherGradientSet {
        let timeOfDay = WeatherGradientGenerator.resolveTimeOfDay(isDaylight: isDaylight, colorScheme: colorScheme)
        let weatherState = WeatherGradientGenerator.resolveWeatherState(condition: condition, temperature: temperature)

        return WeatherGradientSet(
            primary: WeatherGradientGenerator.primaryGradient(timeOfDay: timeOfDay, weatherState: weatherState, colorScheme: colorScheme),
            secondary: WeatherGradientGenerator.secondaryGradient(timeOfDay: timeOfDay, weatherState: weatherState, decision: decision, colorScheme: colorScheme),
            accent: WeatherGradientGenerator.accentColor(weatherState: weatherState, decision: decision),
            particleEffect: WeatherGradientGenerator.particleEffect(weatherState: weatherState, timeOfDay: timeOfDay),
            animationSpeed: WeatherGradientGenerator.animationSpeed(weatherState: weatherState)
        )
    }

    func gradientFor(symbolName: String, colorScheme: ColorScheme) -> LinearGradient {
        let condition = WeatherGradientGenerator.conditionFromSymbol(symbolName)
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
