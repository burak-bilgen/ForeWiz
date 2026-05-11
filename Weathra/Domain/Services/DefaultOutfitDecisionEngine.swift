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
            if wardrobe.hasRaincoat {
                items = [L10n.text("outfit_rainwear")] + items.filter { $0 != L10n.text("outfit_light_jacket") }
            }
            if wardrobe.hasUmbrella {
                accessories.append(L10n.text("outfit_umbrella"))
            } else if wardrobe.hasRaincoat == false {
                warnings.append(L10n.text("outfit_warning_no_gear"))
            }
            warnings.append(L10n.text("outfit_warning_rain"))
        }

        if windRisk {
            items.append(L10n.text("outfit_windbreaker"))
            warnings.append(L10n.text("outfit_warning_wind"))
        }

        if heatRisk || uvRisk {
            if wardrobe.hasSunglasses {
                accessories.append(L10n.text("outfit_sunglasses"))
            }
            accessories.append(contentsOf: [L10n.text("outfit_hat"), L10n.text("outfit_water")])
            if let avoidWindow = input.avoidWindows.first(where: { $0.risk.type == .heat || $0.risk.type == .uv }) {
                warnings.append(String(format: L10n.text("outfit_warning_avoid_format"), avoidWindow.window.shortDisplayText))
            }
        }

        if eveningGetsCooler(hourly: input.hourly, calendar: input.calendar), apparentTemperature < 24 {
            warnings.append(L10n.text("outfit_warning_evening"))
        }

        let outfitTitle = title(for: items, apparentTemperature: apparentTemperature, sensitivity: input.profile.temperatureSensitivity)

        return OutfitRecommendation(
            title: outfitTitle,
            items: Array(Set(items)).sorted(),
            accessories: Array(Set(accessories)).sorted(),
            warning: warnings.first
        )
    }

    private func adjustedTemperature(_ temperature: Double, sensitivity: TemperatureSensitivity) -> Double {
        switch sensitivity {
        case .getsColdEasily: temperature - 3
        case .normal: temperature
        case .getsHotEasily: temperature + 2
        }
    }

    private func baseItems(for apparentTemperature: Double, wardrobe: WardrobePreferences) -> [String] {
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
            let coat = wardrobe.hasWinterCoat ? L10n.text("outfit_winter_coat") : L10n.text("outfit_thick_coat")
            var base = [coat, L10n.text("outfit_sweater"), L10n.text("outfit_closed_shoes")]
            if wardrobe.hasGloves { base.append(L10n.text("outfit_gloves")) }
            if wardrobe.hasThermals { base.append(L10n.text("outfit_thermals")) }
            return base
        }
    }

    private func title(for items: [String], apparentTemperature: Double, sensitivity: TemperatureSensitivity) -> String {
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
        return String(format: L10n.text("outfit_title_balanced_format"), items.prefix(3).joined(separator: ", "))
    }

    private func eveningGetsCooler(hourly: [HourlyWeatherPoint], calendar: Calendar) -> Bool {
        let eveningHours = hourly.filter {
            let hour = calendar.component(.hour, from: $0.date)
            return (18...23).contains(hour)
        }
        guard let dayTemperature = hourly.first?.apparentTemperatureCelsius else { return false }
        return eveningHours.contains { dayTemperature - $0.apparentTemperatureCelsius >= 5 }
    }
}
