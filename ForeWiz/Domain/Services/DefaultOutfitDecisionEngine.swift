import Foundation

struct DefaultOutfitDecisionEngine: OutfitDecisionEngine {
    func recommendOutfit(input: OutfitRecommendationInput) -> OutfitRecommendation {
        let apparentTemperature = input.current.apparentTemperatureCelsius
        let actualTemperature = input.current.temperatureCelsius
        let humidity = input.current.humidity ?? 0.5
        let rainRisk = input.risks.contains { $0.type == .rain && $0.severity >= .medium }
        let windRisk = input.risks.contains { $0.type == .wind && $0.severity >= .medium }
        let heatRisk = input.risks.contains { $0.type == .heat && $0.severity >= .medium }
        let uvRisk = input.risks.contains { $0.type == .uv && $0.severity >= .medium }

        var items = baseItems(for: apparentTemperature)
        var accessories: [String] = []
        var warnings: [String] = []

        if rainRisk {
            items = [L10n.text("outfit_rainwear")] + items.filter { $0 != L10n.text("outfit_light_jacket") }
            accessories.append(L10n.text("outfit_umbrella"))
            warnings.append(L10n.text("outfit_warning_rain"))
        }

        if windRisk {
            items.append(L10n.text("outfit_windbreaker"))
            warnings.append(L10n.text("outfit_warning_wind"))
        }

        if heatRisk || uvRisk {
            accessories.append(L10n.text("outfit_sunglasses"))
            accessories.append(contentsOf: [L10n.text("outfit_hat"), L10n.text("outfit_water")])
            if let avoidWindow = input.avoidWindows.first(where: { $0.risk.type == .heat || $0.risk.type == .uv }) {
                warnings.append(String(format: L10n.text("outfit_warning_avoid_format"), avoidWindow.window.shortDisplayText))
            }
        }

        let eveningCooling = eveningGetsCooler(hourly: input.hourly, calendar: input.calendar)
        if eveningCooling, apparentTemperature < 24 {
            warnings.append(L10n.text("outfit_warning_evening"))
        }

        let outfitTitle = title(for: items, apparentTemperature: apparentTemperature)

        let detailedAdvice = generateAdvice(
            apparentTemp: apparentTemperature,
            actualTemp: actualTemperature,
            humidity: humidity,
            isRainRisk: rainRisk,
            isWindRisk: windRisk,
            isHeatRisk: heatRisk,
            isUVRisk: uvRisk,
            eveningCooling: eveningCooling,
            hourly: input.hourly,
            calendar: input.calendar,
            isDaylight: input.current.isDaylight ?? true
        )

        return OutfitRecommendation(
            title: outfitTitle,
            items: Array(Set(items)).sorted(),
            accessories: Array(Set(accessories)).sorted(),
            warning: warnings.first,
            detailedAdvice: detailedAdvice
        )
    }

    private func baseItems(for apparentTemperature: Double) -> [String] {
        switch apparentTemperature {
        case 30...:
            return [L10n.text("outfit_light_tshirt"), L10n.text("outfit_shorts_pants")]
        case 24..<30:
            return [L10n.text("outfit_tshirt"), L10n.text("outfit_light_pants")]
        case 17..<24:
            return [L10n.text("outfit_tshirt"), L10n.text("outfit_light_jacket"), L10n.text("outfit_casual_pants")]
        case 8..<17:
            return [L10n.text("outfit_sweater"), L10n.text("outfit_light_coat"), L10n.text("outfit_closed_shoes")]
        default:
            return [L10n.text("outfit_winter_coat"), L10n.text("outfit_sweater"), L10n.text("outfit_closed_shoes"), L10n.text("outfit_gloves"), L10n.text("outfit_thermals")]
        }
    }

    private func title(for items: [String], apparentTemperature: Double) -> String {
        if apparentTemperature >= 30 {
            return L10n.text("outfit_title_hot")
        }
        if (17..<24).contains(apparentTemperature) {
            return L10n.text("outfit_title_mild")
        }
        if apparentTemperature < 8 {
            return L10n.text("outfit_title_cold")
        }
        return L10n.text("outfit_title_balanced")
    }

    private func eveningGetsCooler(hourly: [HourlyWeatherPoint], calendar: Calendar) -> Bool {
        let eveningHours = hourly.filter {
            let hour = calendar.component(.hour, from: $0.date)
            return (18...23).contains(hour)
        }
        guard let dayTemperature = hourly.first?.apparentTemperatureCelsius else { return false }
        return eveningHours.contains { dayTemperature - $0.apparentTemperatureCelsius >= 5 }
    }

    private func generateAdvice(
        apparentTemp: Double,
        actualTemp: Double,
        humidity: Double,
        isRainRisk: Bool,
        isWindRisk: Bool,
        isHeatRisk: Bool,
        isUVRisk: Bool,
        eveningCooling: Bool,
        hourly: [HourlyWeatherPoint],
        calendar: Calendar,
        isDaylight: Bool
    ) -> String {
        let isHumid = humidity >= 0.65
        let tempSwing = detectTemperatureSwing(hourly: hourly, calendar: calendar)

        var parts: [String] = []

        parts.append(coreAdvice(apparentTemp: apparentTemp, isHumid: isHumid))

        if let swing = tempSwing, swing >= 8 {
            parts.append(layerForSwingAdvice())
        } else if eveningCooling && apparentTemp < 24 {
            parts.append(eveningLayerAdvice())
        }

        if isRainRisk {
            parts.append(rainAdvice())
        }

        if isWindRisk {
            parts.append(windAdvice())
        }

        if isUVRisk || (isHeatRisk && isDaylight) {
            parts.append(sunProtectionAdvice())
        }

        if isHumid && apparentTemp >= 24 {
            parts.append(humidFabricAdvice())
        }

        return parts.joined(separator: " ")
    }

    private func coreAdvice(apparentTemp: Double, isHumid: Bool) -> String {
        switch apparentTemp {
        case 35...:
            if isHumid {
                return L10n.text("outfit_advice_extreme_humid")
            }
            return L10n.text("outfit_advice_extreme_hot")
        case 30..<35:
            if isHumid {
                return L10n.text("outfit_advice_hot_humid")
            }
            return L10n.text("outfit_advice_hot")
        case 24..<30:
            if isHumid {
                return L10n.text("outfit_advice_warm_humid")
            }
            return L10n.text("outfit_advice_warm")
        case 17..<24:
            return L10n.text("outfit_advice_mild")
        case 10..<17:
            return L10n.text("outfit_advice_cool")
        case 4..<10:
            return L10n.text("outfit_advice_cold")
        default:
            return L10n.text("outfit_advice_freezing")
        }
    }

    private func layerForSwingAdvice() -> String {
        L10n.text("outfit_advice_layer_swing")
    }

    private func eveningLayerAdvice() -> String {
        L10n.text("outfit_advice_evening_layer")
    }

    private func rainAdvice() -> String {
        L10n.text("outfit_advice_rain")
    }

    private func windAdvice() -> String {
        L10n.text("outfit_advice_wind")
    }

    private func sunProtectionAdvice() -> String {
        L10n.text("outfit_advice_sun_protection")
    }

    private func humidFabricAdvice() -> String {
        L10n.text("outfit_advice_humid_fabric")
    }

    private func detectTemperatureSwing(hourly: [HourlyWeatherPoint], calendar: Calendar) -> Double? {
        let morningHours = hourly.filter {
            let hour = calendar.component(.hour, from: $0.date)
            return (6...10).contains(hour)
        }
        let afternoonHours = hourly.filter {
            let hour = calendar.component(.hour, from: $0.date)
            return (12...16).contains(hour)
        }

        guard let morningLow = morningHours.min(by: { $0.apparentTemperatureCelsius < $1.apparentTemperatureCelsius })?.apparentTemperatureCelsius,
              let afternoonHigh = afternoonHours.max(by: { $0.apparentTemperatureCelsius < $1.apparentTemperatureCelsius })?.apparentTemperatureCelsius else {
            return nil
        }

        let swing = afternoonHigh - morningLow
        return swing >= 6 ? swing : nil
    }
}
