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
            hourly: weather.hourlyForecast.forecast.map(hourly(from:)),
            daily: weather.dailyForecast.forecast.map(daily(from:)),
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
            isDaylight: weather.isDaylight,
            severeWeatherRisk: nil
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
            conditionCode: weather.condition.rawValue
        )
    }

    private static func millimetersPerHour(from speed: Measurement<UnitSpeed>) -> Double {
        speed.converted(to: .metersPerSecond).value * 3_600_000
    }
}
