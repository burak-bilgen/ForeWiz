import SwiftUI

enum MetricType: String, CaseIterable, Identifiable {
    case temperature, humidity, wind, uvIndex, precipitation

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .temperature: return L10n.text("metric_temperature")
        case .humidity: return L10n.text("metric_humidity")
        case .wind: return L10n.text("metric_wind")
        case .uvIndex: return L10n.text("metric_uv")
        case .precipitation: return L10n.text("metric_precipitation")
        }
    }

    var unit: String {
        switch self {
        case .temperature: return L10n.text("unit_celsius")
        case .humidity: return L10n.text("unit_percent")
        case .wind: return L10n.text("unit_km_per_h")
        case .uvIndex: return ""
        case .precipitation: return L10n.text("unit_percent")
        }
    }

    var color: Color {
        switch self {
        case .temperature: return .orange
        case .humidity: return .blue
        case .wind: return .cyan
        case .uvIndex: return .purple
        case .precipitation: return .indigo
        }
    }

    func value(from point: HourlyWeatherPoint) -> Double {
        switch self {
        case .temperature: return point.apparentTemperatureCelsius
        case .humidity: return (point.humidity ?? 0) * 100
        case .wind: return point.windSpeedKph ?? 0
        case .uvIndex: return Double(point.uvIndex ?? 0)
        case .precipitation: return (point.precipitationChance ?? 0) * 100
        }
    }

    func currentValue(from snapshot: WeatherSnapshot) -> String {
        let current = snapshot.current
        switch self {
        case .temperature: return "\(Int(current.apparentTemperatureCelsius))\(L10n.text("unit_celsius"))"
        case .humidity: return "\(Int((current.humidity ?? 0) * 100))\(L10n.text("unit_percent"))"
        case .wind: return "\(Int(current.windSpeedKph ?? 0)) \(L10n.text("unit_km_per_h"))"
        case .uvIndex: return "\(current.uvIndex ?? 0)"
        case .precipitation: return "\(Int((current.precipitationChance ?? 0) * 100))\(L10n.text("unit_percent"))"
        }
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case today, next24Hours, tomorrow

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .today: return L10n.text("range_today")
        case .next24Hours: return L10n.text("range_24h")
        case .tomorrow: return L10n.text("range_tomorrow")
        }
    }
}

enum Trend {
    case rising, falling, stable

    var icon: String {
        switch self {
        case .rising: return "arrow.up"
        case .falling: return "arrow.down"
        case .stable: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .rising: return .green
        case .falling: return .red
        case .stable: return .orange
        }
    }

    var description: String {
        switch self {
        case .rising: return L10n.text("trend_increasing")
        case .falling: return L10n.text("trend_decreasing")
        case .stable: return L10n.text("trend_stable")
        }
    }
}

enum ComfortLevel {
    case excellent, good, moderate, poor

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .moderate: return .orange
        case .poor: return .red
        }
    }

    var description: String {
        switch self {
        case .excellent: return L10n.text("comfort_excellent")
        case .good: return L10n.text("comfort_good")
        case .moderate: return L10n.text("comfort_moderate")
        case .poor: return L10n.text("comfort_poor")
        }
    }
}
