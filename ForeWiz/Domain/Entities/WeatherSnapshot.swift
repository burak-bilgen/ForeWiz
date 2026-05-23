import Foundation

struct WeatherAttributionInfo: Codable, Equatable, Identifiable, Sendable {
    let serviceName: String
    let legalPageURLString: String?
    let legalAttributionText: String?

    var id: String {
        [
            serviceName,
            legalPageURLString ?? "",
            legalAttributionText ?? ""
        ].joined(separator: "|")
    }
}

struct WeatherSnapshot: Codable, Equatable, Sendable {
    let location: LocationCoordinate
    let current: CurrentWeatherPoint
    let minute: [MinuteWeatherPoint]?
    let hourly: [HourlyWeatherPoint]
    let daily: [DailyWeatherPoint]
    let alerts: [WeatherAlertInfo]?
    let availability: WeatherAvailabilityInfo?
    let fetchedAt: Date
    let attribution: WeatherAttributionInfo?
    let airQuality: AirQualityInfo?

    init(
        location: LocationCoordinate,
        current: CurrentWeatherPoint,
        minute: [MinuteWeatherPoint]? = nil,
        hourly: [HourlyWeatherPoint],
        daily: [DailyWeatherPoint],
        alerts: [WeatherAlertInfo]? = nil,
        availability: WeatherAvailabilityInfo? = nil,
        fetchedAt: Date,
        attribution: WeatherAttributionInfo?,
        airQuality: AirQualityInfo? = nil
    ) {
        self.location = location
        self.current = current
        self.minute = minute
        self.hourly = hourly
        self.daily = daily
        self.alerts = alerts
        self.availability = availability
        self.fetchedAt = fetchedAt
        self.attribution = attribution
        self.airQuality = airQuality
    }
}

struct MinuteWeatherPoint: Codable, Equatable, Identifiable, Sendable {
    var id: Date { date }

    let date: Date
    let precipitationChance: Double
    let precipitationIntensityMmPerHour: Double
    let precipitationType: String
}

struct WeatherAlertInfo: Codable, Equatable, Identifiable, Sendable {
    var id: String { [summary, region ?? "", source, detailsURLString].joined(separator: "|") }

    let summary: String
    let region: String?
    let source: String
    let severity: RiskLevel
    let detailsURLString: String
}

struct WeatherAvailabilityInfo: Codable, Equatable, Sendable {
    let minuteForecast: String
    let alerts: String
}
