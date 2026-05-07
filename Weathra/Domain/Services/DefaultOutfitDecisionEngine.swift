import Foundation

struct DefaultOutfitDecisionEngine: OutfitDecisionEngine {
    func recommendOutfit(input: OutfitRecommendationInput) -> OutfitRecommendation {
        let apparentTemperature = adjustedTemperature(
            input.current.apparentTemperatureCelsius,
            sensitivity: input.profile.temperatureSensitivity
        )
        let rainRisk = input.risks.contains { $0.type == .rain && $0.severity >= .medium }
        let windRisk = input.risks.contains { $0.type == .wind && $0.severity >= .medium }
        let heatRisk = input.risks.contains { $0.type == .heat && $0.severity >= .medium }
        let uvRisk = input.risks.contains { $0.type == .uv && $0.severity >= .medium }

        let wardrobe = input.profile.wardrobe
        var items = baseItems(for: apparentTemperature, wardrobe: wardrobe)
        var accessories: [String] = []
        var warnings: [String] = []

        if rainRisk {
            let rainWarning = "\(L10n.text("outfit_rainwear")) \(L10n.text("outfit_warning_rain"))"
            
            if wardrobe.hasRaincoat {
                let rainwear = L10n.text("outfit_rainwear")
                let lightJacket = L10n.text("outfit_light_jacket")
                items = [rainwear] + items.filter { $0 != lightJacket }
            }
            
            if wardrobe.hasUmbrella {
                let umbrella = L10n.text("outfit_umbrella")
                accessories.append(umbrella)
            } else if wardrobe.hasRaincoat == false {
                let noGear = L10n.text("outfit_warning_no_gear")
                warnings.append(noGear)
            }
            
            warnings.append(rainWarning)
        }

        if windRisk {
            let windbreaker = L10n.text("outfit_windbreaker")
            items.append(windbreaker)
            let windWarning = L10n.text("outfit_warning_wind")
            warnings.append(windWarning)
        }

        if heatRisk || uvRisk {
            if wardrobe.hasSunglasses {
                let sunglasses = L10n.text("outfit_sunglasses")
                accessories.append(sunglasses)
            }
            let hat = L10n.text("outfit_hat")
            let water = L10n.text("outfit_water")
            accessories.append(contentsOf: [hat, water])
            if let avoidWindow = input.avoidWindows.first(where: { $0.risk.type == .heat || $0.risk.type == .uv }) {
                let warning = L10n.text("outfit_warning_avoid")
                warnings.append("\(avoidWindow.window.shortDisplayText) \(warning)")
            }
        }

        if eveningGetsCooler(hourly: input.hourly, calendar: input.calendar), apparentTemperature < 24 {
            let eveningWarning = L10n.text("outfit_warning_evening")
            warnings.append(eveningWarning)
        }

        let outfitTitle = title(
            for: items,
            apparentTemperature: apparentTemperature,
            sensitivity: input.profile.temperatureSensitivity
        )

        return OutfitRecommendation(
            title: outfitTitle,
            items: Array(Set(items)).sorted(),
            accessories: Array(Set(accessories)).sorted(),
            warning: warnings.first
        )
    }

    private func adjustedTemperature(_ temperature: Double, sensitivity: TemperatureSensitivity) -> Double {
        switch sensitivity {
        case .getsColdEasily:
            temperature - 3
        case .normal:
            temperature
        case .getsHotEasily:
            temperature + 2
        }
    }

    private func baseItems(for apparentTemperature: Double, wardrobe: WardrobePreferences) -> [String] {
        var base: [String]

        switch apparentTemperature {
        case 30...:
            base = [L10n.text("outfit_light_tshirt"), L10n.text("outfit_shorts_pants")]
        case 24..<30:
            base = [L10n.text("outfit_tshirt"), L10n.text("outfit_light_pants")]
        case 17..<24:
            base = [L10n.text("outfit_tshirt"), L10n.text("outfit_light_jacket"), L10n.text("outfit_casual_pants")]
        case 8..<17:
            base = [L10n.text("outfit_sweater"), L10n.text("outfit_light_coat"), L10n.text("outfit_closed_shoes")]
        default:
            let coat = wardrobe.hasWinterCoat ? L10n.text("outfit_winter_coat") : L10n.text("outfit_thick_coat")
            base = [coat, L10n.text("outfit_sweater"), L10n.text("outfit_closed_shoes")]
            if wardrobe.hasGloves {
                let gloves = L10n.text("outfit_gloves")
                base.append(gloves)
            }
            if wardrobe.hasThermals {
                let thermals = L10n.text("outfit_thermals")
                base.append(thermals)
            }
        }

        return base
    }

    private func title(
        for items: [String],
        apparentTemperature: Double,
        sensitivity: TemperatureSensitivity
    ) -> String {
        if apparentTemperature >= 30 {
            return L10n.text("outfit_title_hot")
        }

        if (17..<24).contains(apparentTemperature) {
            return sensitivity == .getsColdEasily
                ? L10n.text("outfit_title_mild_cold")
                : L10n.text("outfit_title_mild")
        }

        if apparentTemperature < 8 {
            return L10n.text("outfit_title_cold")
        }

        return "\(items.prefix(3).joined(separator: ", ")) \(L10n.text("outfit_title_balanced"))"
    }

    private func eveningGetsCooler(hourly: [HourlyWeatherPoint], calendar: Calendar) -> Bool {
        let eveningHours = hourly.filter {
            let hour = calendar.component(.hour, from: $0.date)
            return (18...23).contains(hour)
        }

        guard let dayTemperature = hourly.first?.apparentTemperatureCelsius else {
            return false
        }

        return eveningHours.contains { dayTemperature - $0.apparentTemperatureCelsius >= 5 }
    }
}
