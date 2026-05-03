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
            windRisk(for: hour),
            humidityRisk(for: hour),
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

        if hour.apparentTemperatureCelsius >= 32 && (12..<16).contains(hourOfDay) {
            return WeatherRisk(
                type: .heat,
                severity: hour.apparentTemperatureCelsius >= 35 ? .high : .medium,
                title: "Hissedilen sıcaklık yükseliyor",
                message: "Bu aralıkta hissedilen sıcaklık yüksek. Uzun yürüyüş veya koşu planını daha serin saate al."
            )
        }

        if let uvIndex = hour.uvIndex, uvIndex >= 8 && (11..<16).contains(hourOfDay) {
            return WeatherRisk(
                type: .uv,
                severity: .high,
                title: "Güneş koruması gerekiyor",
                message: "UV seviyesi yükseliyor. Gölge, şapka ve güneş koruması planına dahil edilmeli."
            )
        }

        if (hour.precipitationChance ?? 0) >= 0.75 || (hour.precipitationAmountMm ?? 0) >= 2 {
            return WeatherRisk(
                type: .rain,
                severity: .high,
                title: "Yağmur planı aksatabilir",
                message: "Yağmur ihtimali dış planı aksatabilir. Açık alan planında esnek saat veya kapalı alternatif bırak."
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
            title: "Dışarıda konfor düşük",
            message: "Bu saatlerde dışarıda konfor düşük. Zorunlu değilse planı daha rahat bir aralığa taşı."
        )
    }

    private func stormRisk(for hour: HourlyWeatherPoint) -> WeatherRisk? {
        guard let severeWeatherRisk = hour.severeWeatherRisk, severeWeatherRisk >= .high else {
            return nil
        }

        return WeatherRisk(
            type: .storm,
            severity: severeWeatherRisk,
            title: "Şiddetli hava riski",
            message: "Şiddetli hava riski var; dış planı ertelemek daha güvenli."
        )
    }

    private func heatRisk(for hour: HourlyWeatherPoint, calendar: Calendar) -> WeatherRisk? {
        let hourOfDay = calendar.component(.hour, from: hour.date)

        if hour.apparentTemperatureCelsius >= 35 {
            return WeatherRisk(
                type: .heat,
                severity: hour.apparentTemperatureCelsius >= 39 ? .extreme : .high,
                title: "Sıcaklık yorucu seviyede",
                message: "Hissedilen sıcaklık yüksek. Uzun dış planı kısalt, su ve gölge molası bırak."
            )
        }

        if hour.apparentTemperatureCelsius >= 32 && (12..<16).contains(hourOfDay) {
            return WeatherRisk(
                type: .heat,
                severity: .medium,
                title: "Öğlen sıcaklık artıyor",
                message: "Öğle saatlerinde sıcaklık konforu düşürüyor. Efor gerektiren işleri sabah veya akşama almak daha iyi."
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
            title: "UV koruması gerekli",
            message: "UV yüksek. Kısa süreli planlarda bile güneş koruması ve gölge önemli."
        )
    }

    private func rainRisk(for hour: HourlyWeatherPoint) -> WeatherRisk? {
        let precipitationChance = hour.precipitationChance ?? 0
        let precipitationAmount = hour.precipitationAmountMm ?? 0
        guard precipitationChance >= 0.55 || precipitationAmount >= 1 else {
            return nil
        }

        return WeatherRisk(
            type: .rain,
            severity: precipitationChance >= 0.75 ? .high : .medium,
            title: "Yağmur ihtimali yüksek",
            message: "Yağmur ihtimali yüksek. Şemsiye/yağmurluk al ve açık alan planını kısa tut."
        )
    }

    private func windRisk(for hour: HourlyWeatherPoint) -> WeatherRisk? {
        guard let windSpeed = hour.windSpeedKph, windSpeed >= 30 else {
            return nil
        }

        return WeatherRisk(
            type: .wind,
            severity: windSpeed >= 45 ? .high : .medium,
            title: "Rüzgar açık alanı zorlayabilir",
            message: "Rüzgar açık alan, bisiklet ve sahil gibi korumasız rotaları zorlayabilir."
        )
    }

    private func humidityRisk(for hour: HourlyWeatherPoint) -> WeatherRisk? {
        guard let humidity = hour.humidity, humidity >= 0.78, hour.apparentTemperatureCelsius >= 28 else {
            return nil
        }

        return WeatherRisk(
            type: .humidity,
            severity: humidity >= 0.88 ? .high : .medium,
            title: "Nem sıcaklığı yorucu hissettirir",
            message: "Yüksek nem sıcaklığı daha yorucu hissettirebilir. Eforu azaltmak ve mola vermek iyi olur."
        )
    }

    private func coldRisk(for hour: HourlyWeatherPoint) -> WeatherRisk? {
        guard hour.apparentTemperatureCelsius <= 5 else {
            return nil
        }

        return WeatherRisk(
            type: .cold,
            severity: hour.apparentTemperatureCelsius <= 0 ? .high : .medium,
            title: "Soğuk hissediliyor",
            message: "Hissedilen sıcaklık düşük. Dışarıda uzun kalacaksan ekstra katman ve kapalı ayakkabı iyi olur."
        )
    }
}
