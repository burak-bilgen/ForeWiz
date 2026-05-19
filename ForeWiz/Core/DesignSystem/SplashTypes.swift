import SwiftUI

// MARK: - Enhanced Weather Splash Kind
enum EnhancedWeatherSplashKind: String, CaseIterable {
    case sunny, rainy, snowy, stormy, cloudy, foggy, windy, nightClear

    static func from(symbolName: String) -> EnhancedWeatherSplashKind {
        let s = symbolName.lowercased()
        if s.contains("storm") || s.contains("thunder") || s.contains("bolt") { return .stormy }
        if s.contains("snow") || s.contains("sleet") || s.contains("flurry") { return .snowy }
        if s.contains("rain") || s.contains("drizzle") || s.contains("shower") { return .rainy }
        if s.contains("fog") || s.contains("mist") || s.contains("haze") { return .foggy }
        if s.contains("wind") { return .windy }
        if s.contains("cloud") { return .cloudy }
        if s.contains("moon") || s.contains("night") { return .nightClear }
        return .sunny
    }

    var displayName: String {
        switch self {
        case .sunny: return L10n.text("weather_clear")
        case .rainy: return L10n.text("weather_rain")
        case .snowy: return L10n.text("weather_snow")
        case .stormy: return L10n.text("weather_storm")
        case .cloudy: return L10n.text("weather_cloudy")
        case .foggy: return L10n.text("weather_foggy")
        case .windy: return L10n.text("weather_windy")
        case .nightClear: return L10n.text("weather_clear_night")
        }
    }

    var accentColors: [Color] {
        switch self {
        case .sunny:
            return [
                Color(red: 1.0, green: 0.85, blue: 0.0),
                Color(red: 1.0, green: 0.55, blue: 0.0),
                Color(red: 1.0, green: 0.95, blue: 0.4),
                Color(red: 1.0, green: 0.7, blue: 0.2)
            ]
        case .rainy:
            return [
                Color(red: 0.2, green: 0.45, blue: 0.9),
                Color(red: 0.35, green: 0.65, blue: 1.0),
                Color(red: 0.15, green: 0.35, blue: 0.75),
                Color(red: 0.5, green: 0.75, blue: 1.0)
            ]
        case .snowy:
            return [
                Color(red: 0.85, green: 0.95, blue: 1.0),
                Color(red: 0.7, green: 0.85, blue: 1.0),
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.6, green: 0.8, blue: 0.95)
            ]
        case .stormy:
            return [
                Color(red: 0.4, green: 0.15, blue: 0.7),
                Color(red: 0.7, green: 0.35, blue: 1.0),
                Color(red: 0.25, green: 0.1, blue: 0.5),
                Color(red: 0.9, green: 0.5, blue: 0.2)
            ]
        case .cloudy:
            return [
                Color(red: 0.65, green: 0.7, blue: 0.8),
                Color(red: 0.5, green: 0.55, blue: 0.65),
                Color(red: 0.8, green: 0.82, blue: 0.88),
                Color(red: 0.4, green: 0.45, blue: 0.55)
            ]
        case .foggy:
            return [
                Color(red: 0.7, green: 0.72, blue: 0.78),
                Color(red: 0.55, green: 0.6, blue: 0.68),
                Color(red: 0.85, green: 0.85, blue: 0.88),
                Color(red: 0.45, green: 0.5, blue: 0.58)
            ]
        case .windy:
            return [
                Color(red: 0.3, green: 0.65, blue: 0.95),
                Color(red: 0.6, green: 0.85, blue: 1.0),
                Color(red: 0.2, green: 0.5, blue: 0.8),
                Color(red: 0.75, green: 0.9, blue: 1.0)
            ]
        case .nightClear:
            return [
                Color(red: 0.9, green: 0.85, blue: 0.5),
                Color(red: 0.15, green: 0.2, blue: 0.5),
                Color(red: 0.25, green: 0.35, blue: 0.7),
                Color(red: 1.0, green: 0.95, blue: 0.7)
            ]
        }
    }

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .rainy: return "cloud.heavyrain.fill"
        case .snowy: return "snowflake"
        case .stormy: return "cloud.bolt.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
        case .nightClear: return "moon.stars.fill"
        }
    }

    var secondaryIcon: String? {
        switch self {
        case .sunny: return "sun.haze.fill"
        case .rainy: return "drop.fill"
        case .snowy: return "cloud.snow.fill"
        case .stormy: return "bolt.fill"
        case .cloudy: return "cloud.sun.fill"
        case .foggy: return " humidity.fill"
        case .windy: return "arrow.left.arrow.right"
        case .nightClear: return "sparkles"
        }
    }

    var hapticStyle: HapticStyle {
        switch self {
        case .sunny: return .light
        case .cloudy: return .light
        case .foggy: return .light
        case .nightClear: return .light
        case .windy: return .medium
        case .rainy: return .medium
        case .snowy: return .medium
        case .stormy: return .heavy
        }
    }

    enum HapticStyle {
        case light, medium, heavy
    }
}
