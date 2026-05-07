import Foundation

struct SevereWeatherAlert: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let event: SevereWeatherEvent
    let severity: RiskLevel
    let headline: String
    let description: String
    let instruction: String
    let effective: Date
    let expires: Date
    let areas: [String]
}

enum SevereWeatherEvent: String, Codable, CaseIterable, Hashable, Sendable {
    case tornado
    case flashFlood
    case severeThunderstorm
    case blizzard
    case extremeHeat
    case extremeCold
    case highWind
    case hail
    case denseFog

    var emoji: String {
        switch self {
        case .tornado: return "🌪️"
        case .flashFlood: return "🌊"
        case .severeThunderstorm: return "⛈️"
        case .blizzard: return "❄️"
        case .extremeHeat: return "🔥"
        case .extremeCold: return "🥶"
        case .highWind: return "💨"
        case .hail: return "🧊"
        case .denseFog: return "🌫️"
        }
    }

    var turkishName: String {
        switch self {
        case .tornado: return "Kasırga"
        case .flashFlood: return "Ani Sel"
        case .severeThunderstorm: return "Şiddetli Fırtına"
        case .blizzard: return "Kar Fırtınası"
        case .extremeHeat: return "Aşırı Sıcaklık"
        case .extremeCold: return "Aşırı Soğuk"
        case .highWind: return "Kuvvetli Rüzgar"
        case .hail: return "Dolu"
        case .denseFog: return "Kalın Sis"
        }
    }

    var priorityScore: Int {
        switch self {
        case .tornado: return 100
        case .flashFlood: return 95
        case .blizzard: return 90
        case .extremeHeat: return 85
        case .extremeCold: return 85
        case .severeThunderstorm: return 80
        case .highWind: return 75
        case .hail: return 70
        case .denseFog: return 60
        }
    }
}

final class SevereWeatherAlertService {
    static let shared = SevereWeatherAlertService()

    private init() {}

    func makeAlerts(from risks: [WeatherRisk]) -> [SevereWeatherAlert] {
        let severeRisks = risks.filter { $0.severity >= .high }

        return severeRisks.compactMap { risk in
            mapRiskToAlert(risk)
        }
    }

    private func mapRiskToAlert(_ risk: WeatherRisk) -> SevereWeatherAlert? {
        let event: SevereWeatherEvent

        switch risk.type {
        case .storm:
            event = .severeThunderstorm
        case .heat:
            event = risk.severity == .extreme ? .extremeHeat : .extremeHeat
        case .cold:
            event = .extremeCold
        case .wind:
            event = .highWind
        case .rain:
            event = .flashFlood
        case .uv, .humidity, .poorComfort:
            return nil
        }

        return SevereWeatherAlert(
            id: "alert-\(risk.id)",
            event: event,
            severity: risk.severity,
            headline: "\(event.emoji) \(event.turkishName) Uyarısı",
            description: risk.message,
            instruction: instruction(for: event),
            effective: Date(),
            expires: Date().addingTimeInterval(24 * 60 * 60),
            areas: []
        )
    }

    private func instruction(for event: SevereWeatherEvent) -> String {
        switch event {
        case .tornado:
            return "En yakın sığınak veya bodrum kata git. Pencerelerden uzak dur."
        case .flashFlood:
            return "Araçla veya yaya derelerden geçme. Yüksek noktalara çık."
        case .severeThunderstorm:
            return "Dışarı çıkma. Sağlam bir yapının içinde kal."
        case .blizzard:
            return "Dışarı çıkma. Isı kaybını önle ve bol sıvı al."
        case .extremeHeat:
            return "Bol su iç, klimalı ortamda kal, yoğun fiziksel aktiviteden kaçın."
        case .extremeCold:
            return "Katmanlı giyin, dışarıda geçirme, evde ısıtma kullan."
        case .highWind:
            return "Ağaçlardan ve baskın yapılarından uzak dur. Bisikletten in."
        case .hail:
            return "Araçları kapalı alana park et. Dışarıda isen koruna."
        case .denseFog:
            return "Farları aç, hızını azalt, güvenli mesafeyi koru."
        }
    }

    func shouldNotify(alert: SevereWeatherAlert, isPremium: Bool) -> Bool {
        guard isPremium else { return false }

        let priority: Int
        switch alert.severity {
        case .extreme: priority = 100
        case .high: priority = 90
        case .medium: priority = 70
        case .low: priority = 50
        }

        return priority >= 75
    }
}