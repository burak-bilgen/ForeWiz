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

        return """
        \(emoji) \(temperature)° - \(condition)

        \(decision)
        Skor: \(recommendation.outdoorScore.rawValue)/100

        \(recommendation.summaryText)

        Weathra ile kendi hava durumu asistanın ol!
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
        case .good: return "Dışarı çık!"
        case .moderate: return "Dikkatli ol"
        case .risky: return "Riskli"
        case .avoid: return "Dışarı çıkma"
        }
    }
}