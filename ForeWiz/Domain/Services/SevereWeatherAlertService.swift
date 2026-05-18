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
        case .tornado: return L10n.text("alert_tornado")
        case .flashFlood: return L10n.text("alert_flashFlood")
        case .severeThunderstorm: return L10n.text("weather_storm_severe")
        case .blizzard: return L10n.text("alert_blizzard")
        case .extremeHeat: return L10n.text("alert_extremeHeat")
        case .extremeCold: return L10n.text("alert_extremeCold")
        case .highWind: return L10n.text("alert_highWind")
        case .hail: return L10n.text("alert_hail")
        case .denseFog: return L10n.text("alert_denseFog")
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
        case .uv:
            return nil
        case .humidity:
            return nil
        case .poorComfort:
            return nil
        }

        return SevereWeatherAlert(
            id: "alert-\(risk.id)",
            event: event,
            severity: risk.severity,
            headline: "\(event.emoji) \(event.turkishName) \(L10n.text("alert_warning"))",
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
            return L10n.text("instruction_tornado")
        case .flashFlood:
            return L10n.text("instruction_flashFlood")
        case .severeThunderstorm:
            return L10n.text("instruction_storm")
        case .blizzard:
            return L10n.text("instruction_blizzard")
        case .extremeHeat:
            return L10n.text("instruction_heat")
        case .extremeCold:
            return L10n.text("instruction_cold")
        case .highWind:
            return L10n.text("instruction_wind")
        case .hail:
            return L10n.text("instruction_hail")
        case .denseFog:
            return L10n.text("instruction_fog")
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
