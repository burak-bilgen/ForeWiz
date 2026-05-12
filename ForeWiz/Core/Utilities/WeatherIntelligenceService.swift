import Foundation
import NaturalLanguage

final class WeatherIntelligenceService {
    static let shared = WeatherIntelligenceService()
    private let tagger: NLTagger

    private init() {
        tagger = NLTagger(tagSchemes: [.sentimentScore, .nameType])
    }

    var isAvailable: Bool { true }

    func generateOutfitSuggestion(temperature: String, condition: String, wind: String) async -> String {
        let tempNum = extractNumber(from: temperature)
        let windNum = extractNumber(from: wind)
        let isRainy = condition.lowercased().contains("rain") || condition.lowercased().contains("drizzle")
        let isCold = tempNum.map { $0 < 10 } ?? false
        let isWindy = windNum.map { $0 > 25 } ?? false
        return smartOutfit(isCold: isCold, isRainy: isRainy, isWindy: isWindy, tempNum: tempNum, condition: condition)
    }

    private func smartOutfit(isCold: Bool, isRainy: Bool, isWindy: Bool, tempNum: Double?, condition: String) -> String {
        if isRainy { return "Grab a waterproof jacket and umbrella — rain's in the forecast." }
        if isCold && isWindy { return "Bundle up with a windproof coat and warm layers." }
        if isCold { return "Wear a warm coat and dress in layers to stay comfortable." }
        if isWindy { return "A wind-resistant jacket will keep you comfortable today." }
        if let temp = tempNum {
            if temp > 30 { return "It's hot out — light fabrics, sunscreen, and plenty of water." }
            if temp > 25 { return "Warm day ahead — light clothing and stay hydrated." }
            if temp > 20 { return "Pleasant weather — light layers work perfectly." }
            if temp > 15 { return "A light jacket or sweater should be just right." }
        }
        if condition.lowercased().contains("sun") || condition.lowercased().contains("clear") {
            return "Sunny and clear — dress comfortably and enjoy the day."
        }
        return "Light and comfortable clothing works well today."
    }

    private func extractNumber(from text: String) -> Double? {
        let digits = text.filter { $0.isNumber || $0 == "." || $0 == "-" }
        return Double(digits)
    }
}
