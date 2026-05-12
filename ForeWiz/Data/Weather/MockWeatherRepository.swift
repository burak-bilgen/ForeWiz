import Foundation

final class MockWeatherRepository: WeatherRepository {
    private let dateProvider: DateProvider

    init(dateProvider: DateProvider = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }

    func fetchWeather(for location: LocationCoordinate) async throws -> WeatherSnapshot {
        try await Task.sleep(for: .milliseconds(600))
        let now = dateProvider.now
        let calendar = Calendar.current

        let hourly: [HourlyWeatherPoint] = (0..<48).map { offset in
            let date = calendar.date(byAdding: .hour, value: offset, to: now) ?? now
            let hour = calendar.component(.hour, from: date)
            let isDaylight = (6...20).contains(hour)
            let tempCurve: Double = isDaylight ? 22 + 6 * sin(Double(hour - 6) * .pi / 14) : 16
            let precipChance: Double = (10...14).contains(hour) ? 0.6 : 0.05
            return HourlyWeatherPoint(
                date: date,
                temperatureCelsius: tempCurve + Double.random(in: -1...1),
                apparentTemperatureCelsius: tempCurve - 1.5,
                humidity: 0.55 + Double.random(in: -0.1...0.1),
                windSpeedKph: 14 + Double.random(in: -4...4),
                precipitationChance: precipChance,
                precipitationAmountMm: precipChance > 0.4 ? 1.2 : 0,
                uvIndex: isDaylight ? (hour >= 10 && hour <= 16 ? 5 : 2) : 0,
                conditionCode: precipChance > 0.4 ? "Rain" : (isDaylight ? "Clear" : "Clear"),
                isDaylight: isDaylight,
                severeWeatherRisk: nil
            )
        }

        let daily: [DailyWeatherPoint] = (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: now) ?? now
            let isRainy = offset == 2 || offset == 5
            return DailyWeatherPoint(
                date: date,
                highTemperatureCelsius: 24 + Double.random(in: -3...3),
                lowTemperatureCelsius: 14 + Double.random(in: -2...2),
                precipitationChance: isRainy ? 0.75 : 0.1,
                uvIndex: 5,
                conditionCode: isRainy ? "Rain" : "Clear",
                sunrise: calendar.date(bySettingHour: 6, minute: 30, second: 0, of: date),
                sunset: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: date)
            )
        }

        let current = CurrentWeatherPoint(
            date: now,
            temperatureCelsius: 21.4,
            apparentTemperatureCelsius: 20.1,
            humidity: 0.58,
            windSpeedKph: 16.2,
            precipitationChance: nil,
            precipitationAmountMm: 0,
            uvIndex: 4,
            conditionCode: "PartlyCloudy",
            isDaylight: true,
            severeWeatherRisk: nil
        )

        return WeatherSnapshot(
            location: location,
            current: current,
            hourly: hourly,
            daily: daily,
            fetchedAt: now,
            attribution: WeatherAttributionInfo(
                serviceName: "Mock Weather",
                legalPageURLString: nil,
                legalAttributionText: "Simulator mock data — not real weather"
            )
        )
    }
}
