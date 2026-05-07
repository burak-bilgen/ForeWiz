import SwiftUI
import WidgetKit

enum WidgetStrings {
    static var widgetName: String { "Weathra" }
    static var widgetDescription: String { WidgetLocalization.text("widget_description") }
    static var widgetNoData: String { WidgetLocalization.text("widget_no_data") }
    static var widgetOpenApp: String { WidgetLocalization.text("widget_open_app") }
    static var decisionGood: String { WidgetLocalization.text("widget_decision_good") }
    static var decisionBad: String { WidgetLocalization.text("widget_decision_bad") }
    static var decisionModerate: String { WidgetLocalization.text("widget_decision_moderate") }
    static var outfitLightAndComfortable: String { WidgetLocalization.text("outfit_light_and_comfortable") }
    static var activityRunning: String { WidgetLocalization.text("activity_running") }
}

private enum WidgetLocalization {
    private static let suiteName = "group.weathra"
    private static let languageOverrideKey = "weathra.languageOverride.v1"
    private static let fallbackLanguageCode = "en"

    private static let localizedStrings: [String: [String: String]] = [
        "en": [
            "widget_description": "Today's weather and outdoor recommendation",
            "widget_no_data": "No data",
            "widget_open_app": "Open app",
            "widget_decision_good": "Good to go outside",
            "widget_decision_moderate": "Be careful",
            "widget_decision_bad": "Not recommended outside",
            "outfit_light_and_comfortable": "Light and comfortable",
            "activity_running": "Running"
        ],
        "tr": [
            "widget_description": "Bugünün hava durumu ve dışarı çıkma önerisi",
            "widget_no_data": "Veri yok",
            "widget_open_app": "Uygulamayı aç",
            "widget_decision_good": "Dışarı çıkabilirsiniz",
            "widget_decision_moderate": "Dikkatli olun",
            "widget_decision_bad": "Dışarı çıkmanızı önermiyoruz",
            "outfit_light_and_comfortable": "Hafif ve rahat",
            "activity_running": "Koşu"
        ]
    ]

    static func text(_ key: String) -> String {
        let languageCode = currentLanguageCode
        return localizedStrings[languageCode]?[key]
            ?? localizedStrings[fallbackLanguageCode]?[key]
            ?? key
    }

    static var locale: Locale {
        Locale(identifier: currentLanguageCode)
    }

    private static var currentLanguageCode: String {
        if let override = UserDefaults(suiteName: suiteName)?.string(forKey: languageOverrideKey),
           let languageCode = normalizedLanguageCode(override) {
            return languageCode
        }

        for identifier in Locale.preferredLanguages {
            if let languageCode = normalizedLanguageCode(identifier) {
                return languageCode
            }
        }

        return fallbackLanguageCode
    }

    private static func normalizedLanguageCode(_ identifier: String) -> String? {
        let code = identifier
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .first
            .map(String.init)?
            .lowercased()

        guard code == "en" || code == "tr" else {
            return nil
        }

        return code
    }
}

struct Provider: TimelineProvider {
    private let suiteName = "group.weathra"
    private let key = "weathra_latest_recommendation"

    func placeholder(in context: Context) -> DailyDecisionEntry {
        DailyDecisionEntry(date: Date(), recommendation: WidgetRecommendation.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyDecisionEntry) -> Void) {
        let recommendation = loadRecommendation()
        let entry = DailyDecisionEntry(date: Date(), recommendation: recommendation ?? WidgetRecommendation.placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let recommendation = loadRecommendation()
        let entry = DailyDecisionEntry(date: Date(), recommendation: recommendation)
        let nextUpdateDate = Calendar.current.date(
            byAdding: .hour,
            value: 2,
            to: Date()
        ) ?? Date().addingTimeInterval(7200)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }

    private func loadRecommendation() -> WidgetRecommendation? {
        guard let userDefaults = UserDefaults(suiteName: suiteName),
              let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetRecommendation.self, from: data)
    }
}

struct DailyDecisionEntry: TimelineEntry {
    let date: Date
    let recommendation: WidgetRecommendation?
}

struct WidgetRecommendation: Codable {
    let outdoorDecision: WidgetOutdoorDecision
    let outdoorScore: Int
    let bestOutdoorWindow: WidgetTimeWindow?
    let summaryText: String

    static var placeholder: WidgetRecommendation {
        WidgetRecommendation(
            outdoorDecision: .good,
            outdoorScore: 85,
            bestOutdoorWindow: WidgetTimeWindow(start: Date(), end: Date()),
            summaryText: WidgetStrings.decisionGood
        )
    }
}

enum WidgetOutdoorDecision: String, Codable {
    case good, moderate, bad

    var localizedTitle: String {
        switch self {
        case .good: return WidgetStrings.decisionGood
        case .moderate: return WidgetStrings.decisionModerate
        case .bad: return WidgetStrings.decisionBad
        }
    }
}

struct WidgetTimeWindow: Codable {
    let start: Date
    let end: Date

    var shortDisplayText: String {
        let formatter = DateFormatter()
        formatter.locale = WidgetLocalization.locale
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct WeathraWidgetEntryView: View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            if let recommendation = entry.recommendation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(recommendation.outdoorDecision.localizedTitle)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .lineLimit(2)
                        Spacer(minLength: 4)
                        ScoreRingViewWidget(score: recommendation.outdoorScore)
                    }

                    if family != .systemSmall {
                        Text(recommendation.summaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    Spacer()

                    if let bestWindow = recommendation.bestOutdoorWindow {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.blue)
                            Text(bestWindow.shortDisplayText)
                                .font(.caption2.weight(.bold))
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(WidgetStrings.widgetNoData)
                        .font(.caption.weight(.semibold))
                    Text(WidgetStrings.widgetOpenApp)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct ScoreRingViewWidget: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(tintColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(score)")
                .font(.system(.caption2, design: .rounded, weight: .bold))
        }
        .frame(width: 32, height: 32)
    }

    private var tintColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

@main
struct WeathraWidget: Widget {
    let kind: String = "WeathraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                WeathraWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WeathraWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName(WidgetStrings.widgetName)
        .description(WidgetStrings.widgetDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
