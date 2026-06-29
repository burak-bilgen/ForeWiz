import Foundation
import WizPathKit

@MainActor
final class WizPathLocationServiceAdapter: WizPathLocationSource {
    private let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    func getCurrentLocation() async throws -> WizPathCoordinate {
        let coord = try await locationService.getCurrentLocation()
        return WizPathCoordinate(latitude: coord.latitude, longitude: coord.longitude)
    }
}

@MainActor
final class WizPathWeatherServiceAdapter: WizPathWeatherSource {
    private let weatherRepository: WeatherRepository
    private let dateProvider: DateProvider

    init(weatherRepository: WeatherRepository, dateProvider: DateProvider = SystemDateProvider()) {
        self.weatherRepository = weatherRepository
        self.dateProvider = dateProvider
    }

    func fetchWeather(for coordinate: WizPathCoordinate) async throws -> WizPathWeatherSnapshot {
        let mainCoord = LocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let snapshot = try await weatherRepository.fetchWeather(for: mainCoord)
        return WizPathWeatherSnapshot(
            current: WizPathCurrentWeather(
                temperatureCelsius: snapshot.current.temperatureCelsius,
                conditionCode: snapshot.current.conditionCode,
                symbolName: snapshot.current.symbolName,
                precipitationChance: snapshot.current.precipitationChance,
                windSpeedKph: snapshot.current.windSpeedKph
            ),
            hourly: snapshot.hourly.map { h in
                WizPathHourlyForecast(
                    date: h.date,
                    temperatureCelsius: h.temperatureCelsius,
                    conditionCode: h.conditionCode,
                    symbolName: h.symbolName,
                    precipitationChance: h.precipitationChance,
                    windSpeedKph: h.windSpeedKph
                )
            },
            daily: snapshot.daily.map { d in
                WizPathDailyForecast(
                    date: d.date,
                    highCelsius: d.highTemperatureCelsius,
                    lowCelsius: d.lowTemperatureCelsius,
                    conditionCode: d.conditionCode,
                    symbolName: d.symbolName
                )
            }
        )
    }
}
