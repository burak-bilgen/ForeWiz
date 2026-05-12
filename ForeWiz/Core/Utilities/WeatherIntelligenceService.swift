import Foundation

final class WeatherIntelligenceService {
    static let shared = WeatherIntelligenceService()

    var isAvailable: Bool { false }

    func generateOutfitSuggestion(temperature: String, condition: String, wind: String) async -> String {
        let tempNum = extractNumber(from: temperature)
        let windNum = extractNumber(from: wind)
        let isRainy = condition.lowercased().contains("rain") || condition.lowercased().contains("drizzle")
        let isCold = tempNum.map { $0 < 10 } ?? false
        let isWindy = windNum.map { $0 > 25 } ?? false
        return fallbackOutfit(isCold: isCold, isRainy: isRainy, isWindy: isWindy)
    }

    private func extractNumber(from text: String) -> Double? {
        let digits = text.filter { $0.isNumber || $0 == "." || $0 == "-" }
        return Double(digits)
    }

    private func fallbackOutfit(isCold: Bool, isRainy: Bool, isWindy: Bool) -> String {
        if isCold && isRainy { return "Wear a warm waterproof jacket with layers." }
        if isCold && isWindy { return "Wear a windproof jacket with warm layers underneath." }
        if isCold { return "Wear a warm coat, scarf, and comfortable layers." }
        if isRainy { return "Bring a waterproof jacket and umbrella." }
        if isWindy { return "Wear a wind-resistant jacket and secure any loose items." }
        return "Light and comfortable clothing works well today."
    }
}
