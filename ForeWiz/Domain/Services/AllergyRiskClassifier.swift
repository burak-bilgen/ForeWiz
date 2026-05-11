import Foundation

protocol AllergyRiskClassifier: Sendable {
    func classifyPollenRisk(for hour: HourlyWeatherPoint) -> WeatherRisk?
    func classifyAirQualityRisk(for hour: HourlyWeatherPoint, profile: AllergyProfile) -> WeatherRisk?
}

final class DefaultAllergyRiskClassifier: AllergyRiskClassifier, @unchecked Sendable {
    func classifyPollenRisk(for hour: HourlyWeatherPoint) -> WeatherRisk? {
        guard let pollenLevel = hour.pollenLevel else {
            return nil
        }

        guard pollenLevel.severity >= 3 else {
            return nil
        }

        let severity: RiskLevel
        switch pollenLevel {
        case .moderate:
            severity = .medium
        case .high:
            severity = .high
        case .veryHigh:
            severity = .extreme
        default:
            return nil
        }

        return WeatherRisk(
            type: .pollen,
            severity: severity,
            title: L10n.text("risk_pollen_high"),
            message: L10n.text("risk_pollen_message")
        )
    }

    func classifyAirQualityRisk(for hour: HourlyWeatherPoint, profile: AllergyProfile) -> WeatherRisk? {
        guard profile.isEnabled else {
            return nil
        }

        var risks: [WeatherRisk] = []

        if let aqi = hour.airQualityIndex, aqi.severity >= 3 {
            risks.append(WeatherRisk(
                type: .airQuality,
                severity: aqi.severity >= 5 ? .high : .medium,
                title: L10n.text("risk_air_quality"),
                message: L10n.text("risk_air_message")
            ))
        }

        if let pm25 = hour.pm25Level, pm25.severity >= 3 {
            risks.append(WeatherRisk(
                type: .airQuality,
                severity: pm25.severity >= 5 ? .high : .medium,
                title: L10n.text("risk_pm25"),
                message: L10n.text("risk_pm25_message")
            ))
        }

        return risks.max(by: { $0.severity.rawValue < $1.severity.rawValue })
    }
}
