import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension View {
    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        background(
            ShareSheet(activityItems: items)
                .hidden()
                .onAppear { isPresented.wrappedValue = true }
                .onDisappear { isPresented.wrappedValue = false }
        )
    }
}

struct RecommendationShareContent {
    static func create(from recommendation: DailyRecommendation, temperature: Int, condition: String) -> String {
        let emoji = emojiFor(condition: condition)
        let decision = decisionText(for: recommendation.outdoorDecision)
        let scoreLabel = copy(tr: "Skor", en: "Score")
        let footer = copy(
            tr: "Weathra ile hava durumunu plan asistanına çevir.",
            en: "Turn weather into a planning assistant with Weathra."
        )

        return """
        \(emoji) \(temperature)° - \(condition)

        \(decision)
        \(scoreLabel): \(recommendation.outdoorScore.rawValue)/100

        \(recommendation.summaryText)

        \(footer)
        🌤️ weathra.app
        """
    }

    private static func emojiFor(condition: String) -> String {
        let lowercased = condition.lowercased()
        if lowercased.contains("clear") || lowercased.contains("sun") {
            return "☀️"
        } else if lowercased.contains("cloud") {
            return "☁️"
        } else if lowercased.contains("rain") {
            return "🌧️"
        } else if lowercased.contains("snow") {
            return "❄️"
        } else if lowercased.contains("thunder") {
            return "⛈️"
        } else if lowercased.contains("fog") || lowercased.contains("mist") {
            return "🌫️"
        }
        return "🌤️"
    }

    private static func decisionText(for decision: OutdoorDecision) -> String {
        switch decision {
        case .good:
            return copy(tr: "Dış plan için iyi görünüyor.", en: "Looks good for outdoor plans.")
        case .moderate:
            return copy(tr: "Küçük önlemle dışarı çıkılır.", en: "Outdoor plans work with small precautions.")
        case .risky:
            return copy(tr: "Risk var; planı esnek tut.", en: "There is some risk; keep the plan flexible.")
        case .avoid:
            return copy(tr: "Bugün içeri almak daha mantıklı.", en: "Moving the plan indoors is the better call today.")
        }
    }

    private static func copy(tr: String, en: String) -> String {
        L10n.currentLanguageCode == "tr" ? tr : en
    }
}
