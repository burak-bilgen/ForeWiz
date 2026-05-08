import Foundation

enum NotificationContentFactory {
    static func titleAndBody(for plan: NotificationPlan) -> (title: String, body: String) {
        let enrichedTitle = enrichTitle(for: plan)
        let enrichedBody = enrichBody(for: plan)
        return (enrichedTitle, enrichedBody)
    }

    static private func enrichTitle(for plan: NotificationPlan) -> String {
        let emoji = emojiForCategory(plan.category)
        return "\(emoji) \(plan.title)"
    }

    static private func enrichBody(for plan: NotificationPlan) -> String {
        var body = plan.body

        // Add helpful context based on category
        switch plan.category {
        case .morningBriefing:
            body += "\n\n🌅 İyi günler!"
        case .outfitSuggestion:
            body += "\n\n👗 Bugün için hazır!"
        case .bestRunWindow:
            body += "\n\n🏃 Şimdi zamanı!"
        case .avoidHeatWindow:
            body += "\n\n🥵 Sıcaklık uyarısı"
        case .uvWarning:
            body += "\n\n☀️ UV koruma gerekli"
        case .rainWarning:
            body += "\n\n🌧️ Şemsiye almayı unutma"
        case .windWarning:
            body += "\n\n💨 Rüzgarlı"
        default:
            break
        }

        return body
    }

    static private func emojiForCategory(_ category: NotificationCategory) -> String {
        switch category {
        case .morningBriefing: return "🌅"
        case .outfitSuggestion: return "👕"
        case .bestRunWindow: return "🏃"
        case .avoidHeatWindow: return "🥵"
        case .uvWarning: return "☀️"
        case .rainWarning: return "🌧️"
        case .windWarning: return "💨"
        }
    }
}
