import Foundation
import WeatherKit

enum WeatherMapper {
    static func snapshot(
        from weather: WeatherKit.Weather,
        location: LocationCoordinate,
        fetchedAt: Date,
        attribution: WeatherAttributionInfo?
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            location: location,
            current: current(from: weather.currentWeather),
            minute: weather.minuteForecast?.forecast.map(minute(from:)),
            hourly: weather.hourlyForecast.forecast.map(hourly(from:)),
            daily: weather.dailyForecast.forecast.map(daily(from:)),
            alerts: weather.weatherAlerts?.map(alert(from:)),
            availability: availability(from: weather.availability),
            fetchedAt: fetchedAt,
            attribution: attribution
        )
    }

    private static func current(from weather: CurrentWeather) -> CurrentWeatherPoint {
        CurrentWeatherPoint(
            date: weather.date,
            temperatureCelsius: weather.temperature.converted(to: .celsius).value,
            apparentTemperatureCelsius: weather.apparentTemperature.converted(to: .celsius).value,
            humidity: weather.humidity,
            windSpeedKph: weather.wind.speed.converted(to: .kilometersPerHour).value,
            precipitationChance: nil,
            precipitationAmountMm: millimetersPerHour(from: weather.precipitationIntensity),
            uvIndex: weather.uvIndex.value,
            conditionCode: weather.condition.rawValue,
            symbolName: weather.symbolName,
            isDaylight: weather.isDaylight,
            severeWeatherRisk: nil
        )
    }

    private static func minute(from weather: MinuteWeather) -> MinuteWeatherPoint {
        MinuteWeatherPoint(
            date: weather.date,
            precipitationChance: weather.precipitationChance,
            precipitationIntensityMmPerHour: millimetersPerHour(from: weather.precipitationIntensity),
            precipitationType: weather.precipitation.rawValue
        )
    }

    private static func hourly(from weather: HourWeather) -> HourlyWeatherPoint {
        HourlyWeatherPoint(
            date: weather.date,
            temperatureCelsius: weather.temperature.converted(to: .celsius).value,
            apparentTemperatureCelsius: weather.apparentTemperature.converted(to: .celsius).value,
            humidity: weather.humidity,
            windSpeedKph: weather.wind.speed.converted(to: .kilometersPerHour).value,
            precipitationChance: weather.precipitationChance,
            precipitationAmountMm: weather.precipitationAmount.converted(to: .millimeters).value,
            uvIndex: weather.uvIndex.value,
            conditionCode: weather.condition.rawValue,
            symbolName: weather.symbolName,
            isDaylight: weather.isDaylight,
            severeWeatherRisk: nil
        )
    }

    private static func daily(from weather: DayWeather) -> DailyWeatherPoint {
        DailyWeatherPoint(
            date: weather.date,
            highTemperatureCelsius: weather.highTemperature.converted(to: .celsius).value,
            lowTemperatureCelsius: weather.lowTemperature.converted(to: .celsius).value,
            precipitationChance: weather.precipitationChance,
            uvIndex: weather.uvIndex.value,
            conditionCode: weather.condition.rawValue,
            symbolName: weather.symbolName,
            sunrise: weather.sun.sunrise,
            sunset: weather.sun.sunset
        )
    }

    private static func alert(from weather: WeatherAlert) -> WeatherAlertInfo {
        WeatherAlertInfo(
            summary: weather.summary,
            region: weather.region,
            source: weather.source,
            severity: riskLevel(from: weather.severity),
            detailsURLString: weather.detailsURL.absoluteString
        )
    }

    private static func availability(from weather: WeatherAvailability) -> WeatherAvailabilityInfo {
        WeatherAvailabilityInfo(
            minuteForecast: weather.minuteAvailability.rawValue,
            alerts: weather.alertAvailability.rawValue
        )
    }

    private static func riskLevel(from severity: WeatherSeverity) -> RiskLevel {
        switch severity {
        case .minor:
            return .low
        case .moderate:
            return .medium
        case .severe:
            return .high
        case .extreme:
            return .extreme
        case .unknown:
            return .medium
        @unknown default:
            return .medium
        }
    }

    private static func millimetersPerHour(from speed: Measurement<UnitSpeed>) -> Double {
        speed.converted(to: .metersPerSecond).value * 3_600_000
    }
}
