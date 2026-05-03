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

        var items = baseItems(for: apparentTemperature)
        var accessories: [String] = []
        var warnings: [String] = []

        if rainRisk {
            items = ["Yağmurluk veya su geçirmez mont"] + items.filter { $0 != "İnce ceket" }
            accessories.append("Şemsiye")
            warnings.append("Yağmur ihtimali belirgin; şemsiye veya yağmurluk iyi olur.")
        }

        if windRisk {
            items.append("Rüzgar geçirmeyen hafif katman")
            warnings.append("Rüzgar hissedilen sıcaklığı düşürebilir.")
        }

        if heatRisk || uvRisk {
            accessories.append(contentsOf: ["Güneş gözlüğü", "Şapka", "Su"])
            if let avoidWindow = input.avoidWindows.first(where: { $0.risk.type == .heat || $0.risk.type == .uv }) {
                warnings.append("\(avoidWindow.window.shortDisplayText) arası uzun süre dışarıda kalmamaya çalış.")
            }
        }

        if eveningGetsCooler(hourly: input.hourly, calendar: input.calendar), apparentTemperature < 24 {
            warnings.append("Akşam serinleyebilir; ince bir katman iyi olur.")
        }

        let title = title(
            for: items,
            apparentTemperature: apparentTemperature,
            sensitivity: input.profile.temperatureSensitivity
        )

        return OutfitRecommendation(
            title: title,
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

    private func baseItems(for apparentTemperature: Double) -> [String] {
        switch apparentTemperature {
        case 30...:
            ["Hafif tişört", "Şort veya ince pantolon"]
        case 24..<30:
            ["Tişört", "İnce pantolon"]
        case 17..<24:
            ["Tişört", "İnce ceket", "Rahat pantolon"]
        case 8..<17:
            ["Kazak", "İnce mont", "Kapalı ayakkabı"]
        default:
            ["Mont", "Kazak", "Kapalı ayakkabı"]
        }
    }

    private func title(
        for items: [String],
        apparentTemperature: Double,
        sensitivity: TemperatureSensitivity
    ) -> String {
        if apparentTemperature >= 30 {
            return "Hafif, nefes alan parçalar iyi olur."
        }

        if (17..<24).contains(apparentTemperature) {
            return sensitivity == .getsColdEasily
                ? "Tişört ve ince ceket dengeli olur."
                : "Tişört ve hafif bir katman yeterli."
        }

        if apparentTemperature < 8 {
            return "Sıcak tutan katmanlar ve kapalı ayakkabı iyi olur."
        }

        return "\(items.prefix(3).joined(separator: ", ")) dengeli olur."
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
