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
        if isRainy { return "Yağmur var — yanına şemsiye ve su geçirmez bir şey al." }
        if isCold && isWindy { return "Rüzgar geçirmez bir mont ve kat kat giyinmek iyi olur." }
        if isCold { return "Hava soğuk, kalın bir mont ve katmanlı giyinmekte fayda var." }
        if isWindy { return "Rüzgarlı bir gün — rüzgar geçirmez bir ceket rahat ettirir." }
        if let temp = tempNum {
            if temp > 30 { return "Hava çok sıcak — ince kumaşlar, güneş kremi ve bol su." }
            if temp > 25 { return "Sıcak bir gün — hafif giysiler ve bol sıvı iyi gelir." }
            if temp > 20 { return "Keyifli bir hava — ince bir şeyler giymek yeterli." }
            if temp > 15 { return "Hafif bir ceket veya hırka ideal olur." }
        }
        if condition.lowercased().contains("sun") || condition.lowercased().contains("clear") {
            return "Güneşli ve açık bir gün — rahat giyin ve keyfini çıkar."
        }
        return "Hafif ve rahat kıyafetler bugün için uygun."
    }

    private func extractNumber(from text: String) -> Double? {
        let digits = text.filter { $0.isNumber || $0 == "." || $0 == "-" }
        return Double(digits)
    }
}
