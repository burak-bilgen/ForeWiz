import Foundation

struct DefaultWeatherRiskClassifier {
    let activityWindowScoringEngine: ActivityWindowScoringEngine

    func uniqueRisks(
        from hourly: [HourlyWeatherPoint],
        current: CurrentWeatherPoint,
        calendar: Calendar
    ) -> [WeatherRisk] {
        let currentAsHour = HourlyWeatherPoint(
            date: current.date,
            temperatureCelsius: current.temperatureCelsius,
            apparentTemperatureCelsius: current.apparentTemperatureCelsius,
            humidity: current.humidity,
            windSpeedKph: current.windSpeedKph,
            precipitationChance: current.precipitationChance,
            precipitationAmountMm: current.precipitationAmountMm,
            uvIndex: current.uvIndex,
            conditionCode: current.conditionCode,
            isDaylight: current.isDaylight,
            severeWeatherRisk: current.severeWeatherRisk
        )

        let allRisks = ([currentAsHour] + hourly).flatMap { risks(for: $0, calendar: calendar) }
        var bestByType: [WeatherRiskType: WeatherRisk] = [:]

        for risk in allRisks {
            if let existing = bestByType[risk.type], risk.severity <= existing.severity {
                continue
            }
            bestByType[risk.type] = risk
        }

        return bestByType.values.sorted {
            if $0.severity == $1.severity {
                return $0.type.rawValue < $1.type.rawValue
            }
            return $0.severity > $1.severity
        }
    }

    func makeAvoidWindows(
        from hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        calendar: Calendar
    ) -> [AvoidWindowRecommendation] {
        let riskyHours = hourly.compactMap { hour -> (hour: HourlyWeatherPoint, risk: WeatherRisk)? in
            guard let risk = primaryAvoidRisk(for: hour, profile: profile, calendar: calendar) else {
                return nil
            }
            return (hour, risk)
        }

        guard riskyHours.isEmpty == false else {
            return []
        }

        var windows: [AvoidWindowRecommendation] = []
        var currentHours: [HourlyWeatherPoint] = []
        var currentRisk: WeatherRisk?

        for item in riskyHours {
            if shouldMerge(item: item, into: currentHours, currentRisk: currentRisk, calendar: calendar) {
                currentHours.append(item.hour)
            } else {
                appendAvoidWindow(hours: currentHours, risk: currentRisk, calendar: calendar, into: &windows)
                currentHours = [item.hour]
                currentRisk = item.risk
            }
        }

        appendAvoidWindow(hours: currentHours, risk: currentRisk, calendar: calendar, into: &windows)
        return windows
    }

    func risks(for hour: HourlyWeatherPoint, calendar: Calendar) -> [WeatherRisk] {
        [
            stormRisk(for: hour),
            heatRisk(for: hour, calendar: calendar),
            uvRisk(for: hour, calendar: calendar),
            rainRisk(for: hour),
            coldRisk(for: hour)
        ].compactMap { $0 }
    }

    private func shouldMerge(
        item: (hour: HourlyWeatherPoint, risk: WeatherRisk),
        into currentHours: [HourlyWeatherPoint],
        currentRisk: WeatherRisk?,
        calendar: Calendar
    ) -> Bool {
        guard
            let lastHour = currentHours.last,
            let expectedNext = calendar.date(byAdding: .hour, value: 1, to: lastHour.date)
        else {
            return false
        }

        return expectedNext == item.hour.date && currentRisk?.type == item.risk.type
    }

    private func appendAvoidWindow(
        hours: [HourlyWeatherPoint],
        risk: WeatherRisk?,
        calendar: Calendar,
        into windows: inout [AvoidWindowRecommendation]
    ) {
        guard let first = hours.first, let last = hours.last, let risk else {
            return
        }

        let end = calendar.date(byAdding: .hour, value: 1, to: last.date) ?? last.date
        let window = TimeWindow(start: first.date, end: end)
        windows.append(
            AvoidWindowRecommendation(
                window: window,
                risk: risk,
                reason: risk.message,
                severity: risk.severity
            )
        )
    }

    private func primaryAvoidRisk(
        for hour: HourlyWeatherPoint,
        profile: UserComfortProfile,
        calendar: Calendar
    ) -> WeatherRisk? {
        let hourOfDay = calendar.component(.hour, from: hour.date)

        if let stormRisk = risks(for: hour, calendar: calendar).first(where: { $0.type == .storm }) {
            return stormRisk
        }

        if hour.apparentTemperatureCelsius >= 35 && (11..<17).contains(hourOfDay) {
            return WeatherRisk(
                type: .heat,
                severity: hour.apparentTemperatureCelsius >= 38 ? .high : .medium,
                title: L10n.text("risk_feels_like_rising"),
                message: L10n.text("risk_feels_like_high")
            )
        }

        // 🌙 Night heat avoidance — serinlemek için gece saatleri
        if !(6..<22).contains(hourOfDay) && hour.apparentTemperatureCelsius >= 24 {
            return WeatherRisk(
                type: .heat,
                severity: .medium,
                title: L10n.text("risk_night_heat"),
                message: L10n.text("risk_night_heat_message")
            )
        }

        if let uvIndex = hour.uvIndex, uvIndex >= 8 && (11..<16).contains(hourOfDay) {
            return WeatherRisk(
                type: .uv,
                severity: .high,
                title: L10n.text("risk_sun_protection"),
                message: L10n.text("risk_uv_high")
            )
        }

        if (hour.precipitationChance ?? 0) >= 0.7 || (hour.precipitationAmountMm ?? 0) >= 2 {
            return WeatherRisk(
                type: .rain,
                severity: .high,
                title: L10n.text("risk_rain_disrupt"),
                message: L10n.text("risk_rain_message")
            )
        }

        return poorComfortRisk(for: hour, profile: profile, calendar: calendar)
    }

    private func poorComfortRisk(
        for hour: HourlyWeatherPoint,
        profile: UserComfortProfile,
        calendar: Calendar
    ) -> WeatherRisk? {
        let score = activityWindowScoringEngine.score(
            hour: hour,
            activity: .goingOutside,
            profile: profile,
            calendar: calendar
        )

        guard score.rawValue < 40 else {
            return nil
        }

        return WeatherRisk(
            type: .poorComfort,
            severity: .medium,
            title: L10n.text("risk_poor_comfort"),
            message: L10n.text("risk_poor_comfort_message")
        )
    }

    private func stormRisk(for hour: HourlyWeatherPoint) -> WeatherRisk? {
        guard let severeWeatherRisk = hour.severeWeatherRisk, severeWeatherRisk >= .high else {
            return nil
        }

        return WeatherRisk(
            type: .storm,
            severity: severeWeatherRisk,
            title: L10n.text("risk_severe_weather"),
            message: L10n.text("risk_severe_weather_message")
        )
    }

    private func heatRisk(for hour: HourlyWeatherPoint, calendar: Calendar) -> WeatherRisk? {
        let hourOfDay = calendar.component(.hour, from: hour.date)
        let apparentTemp = hour.apparentTemperatureCelsius

        // 🌙 Night Heat (Tropikal Gece) — >20°C at night disrupts sleep & recovery
        if !(6..<20).contains(hourOfDay) && apparentTemp > 20 {
            let severity: RiskLevel = apparentTemp >= 25 ? .high : .medium
            return WeatherRisk(
                type: .heat,
                severity: severity,
                title: L10n.text("risk_night_heat"),
                message: L10n.text("risk_night_heat_message")
            )
        }

        // ☀️ Daytime Heat — kademeli threshold (küresel ısınma odaklı)
        // Kritik: 40°C+ → extreme
        // Ekstrem: 36°C+ → high
        // Yüksek: 32°C+ → medium (gün ortası)
        // Uyarı: 28°C+ → low (erken uyarı)
        if apparentTemp >= 40 {
            return WeatherRisk(
                type: .heat,
                severity: .extreme,
                title: L10n.text("risk_critical_heat"),
                message: L10n.text("risk_critical_heat_message")
            )
        }

        if apparentTemp >= 36 {
            return WeatherRisk(
                type: .heat,
                severity: .high,
                title: L10n.text("risk_hot_exhausting"),
                message: L10n.text("risk_feels_high_message")
            )
        }

        if apparentTemp >= 32 && (11..<17).contains(hourOfDay) {
            return WeatherRisk(
                type: .heat,
                severity: .medium,
                title: L10n.text("risk_midday_heating"),
                message: L10n.text("risk_midday_message")
            )
        }

        if apparentTemp >= 28 && (11..<16).contains(hourOfDay) {
            return WeatherRisk(
                type: .heat,
                severity: .low,
                title: L10n.text("risk_early_heat_warning"),
                message: L10n.text("risk_early_heat_message")
            )
        }

        return nil
    }

    private func uvRisk(for hour: HourlyWeatherPoint, calendar: Calendar) -> WeatherRisk? {
        let hourOfDay = calendar.component(.hour, from: hour.date)
        guard let uvIndex = hour.uvIndex, uvIndex >= 7, (11..<16).contains(hourOfDay) else {
            return nil
        }

        return WeatherRisk(
            type: .uv,
            severity: uvIndex >= 9 ? .high : .medium,
            title: L10n.text("risk_uv_need"),
            message: L10n.text("risk_uv_message")
        )
    }

    private func rainRisk(for hour: HourlyWeatherPoint) -> WeatherRisk? {
        let precipitationChance = hour.precipitationChance ?? 0
        let precipitationAmount = hour.precipitationAmountMm ?? 0
        guard precipitationChance >= 0.5 || precipitationAmount >= 1 else {
            return nil
        }

        return WeatherRisk(
            type: .rain,
            severity: precipitationChance >= 0.75 ? .high : .medium,
            title: L10n.text("risk_rain_high"),
            message: L10n.text("risk_rain_message2")
        )
    }

    private func coldRisk(for hour: HourlyWeatherPoint) -> WeatherRisk? {
        guard hour.apparentTemperatureCelsius <= 5 else {
            return nil
        }

        return WeatherRisk(
            type: .cold,
            severity: hour.apparentTemperatureCelsius <= 0 ? .high : .medium,
            title: L10n.text("risk_cold_feels"),
            message: L10n.text("risk_cold_message")
        )
    }
}
