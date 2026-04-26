import Foundation
@testable import WeatherAssistant

enum WeatherTestFixtures {
    static let timeZone = TimeZone(secondsFromGMT: 3) ?? .current

    static func date(year: Int = 2026, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func profile(
        sensitivity: TemperatureSensitivity = .normal,
        activities: Set<ActivityType> = [.running, .walking, .cycling, .goingOutside],
        quietHours: TimeWindow? = nil,
        maximumDailyNotifications: Int = 2
    ) -> UserComfortProfile {
        UserComfortProfile(
            temperatureSensitivity: sensitivity,
            preferredActivities: activities,
            quietHours: quietHours,
            notificationPreferences: NotificationCategory.allCases.map {
                let preferredTime = $0 == .morningBriefing ? DateComponents(hour: 8, minute: 0) : nil
                return NotificationPreference(category: $0, isEnabled: true, preferredTime: preferredTime)
            },
            maximumDailyNotifications: maximumDailyNotifications
        )
    }

    static func snapshot(
        now: Date,
        temperature: (Int) -> Double,
        apparentTemperature: (Int) -> Double,
        humidity: (Int) -> Double? = { _ in 0.45 },
        windSpeed: (Int) -> Double? = { _ in 10 },
        precipitationChance: (Int) -> Double? = { _ in 0.05 },
        precipitationAmount: (Int) -> Double? = { _ in 0 },
        uvIndex: (Int) -> Int? = { _ in 2 },
        severeRisk: (Int) -> RiskLevel? = { _ in nil }
    ) -> WeatherSnapshot {
        let calendar = calendar
        let start = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now
        let hourly = (0..<18).compactMap { offset -> HourlyWeatherPoint? in
            guard let date = calendar.date(byAdding: .hour, value: offset, to: start) else {
                return nil
            }

            let hour = calendar.component(.hour, from: date)
            return HourlyWeatherPoint(
                date: date,
                temperatureCelsius: temperature(hour),
                apparentTemperatureCelsius: apparentTemperature(hour),
                humidity: humidity(hour),
                windSpeedKph: windSpeed(hour),
                precipitationChance: precipitationChance(hour),
                precipitationAmountMm: precipitationAmount(hour),
                uvIndex: uvIndex(hour),
                conditionCode: "test",
                isDaylight: (6...20).contains(hour),
                severeWeatherRisk: severeRisk(hour)
            )
        }

        let currentHour = calendar.component(.hour, from: now)
        let current = CurrentWeatherPoint(
            date: now,
            temperatureCelsius: temperature(currentHour),
            apparentTemperatureCelsius: apparentTemperature(currentHour),
            humidity: humidity(currentHour),
            windSpeedKph: windSpeed(currentHour),
            precipitationChance: precipitationChance(currentHour),
            precipitationAmountMm: precipitationAmount(currentHour),
            uvIndex: uvIndex(currentHour),
            conditionCode: "test",
            isDaylight: true,
            severeWeatherRisk: severeRisk(currentHour)
        )

        return WeatherSnapshot(
            location: LocationCoordinate(latitude: 36.8969, longitude: 30.7133),
            current: current,
            hourly: hourly,
            daily: [],
            fetchedAt: now,
            attribution: nil
        )
    }
}
