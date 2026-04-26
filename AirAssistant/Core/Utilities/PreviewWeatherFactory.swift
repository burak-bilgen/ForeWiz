import Foundation

enum PreviewWeatherFactory {
    static func dailyRecommendation() -> DailyRecommendation {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        let hourly = (0..<14).compactMap { offset -> HourlyWeatherPoint? in
            guard let date = calendar.date(byAdding: .hour, value: offset, to: start) else {
                return nil
            }

            let hour = calendar.component(.hour, from: date)
            let isMidday = (12..<16).contains(hour)
            return HourlyWeatherPoint(
                date: date,
                temperatureCelsius: isMidday ? 31 : 24,
                apparentTemperatureCelsius: isMidday ? 34 : 25,
                humidity: 0.55,
                windSpeedKph: 14,
                precipitationChance: 0.12,
                precipitationAmountMm: 0,
                uvIndex: isMidday ? 7 : 3,
                conditionCode: "partlyCloudy",
                isDaylight: true,
                severeWeatherRisk: nil
            )
        }
        let current = CurrentWeatherPoint(
            date: now,
            temperatureCelsius: 24,
            apparentTemperatureCelsius: 25,
            humidity: 0.55,
            windSpeedKph: 14,
            precipitationChance: 0.12,
            precipitationAmountMm: 0,
            uvIndex: 3,
            conditionCode: "partlyCloudy",
            isDaylight: true,
            severeWeatherRisk: nil
        )
        let snapshot = WeatherSnapshot(
            location: LocationCoordinate(latitude: 41.0082, longitude: 28.9784),
            current: current,
            hourly: hourly,
            daily: [],
            fetchedAt: now,
            attribution: nil
        )

        return DefaultWeatherDecisionEngine().makeDailyRecommendation(
            snapshot: snapshot,
            profile: .default,
            now: now,
            calendar: calendar
        )
    }
}
