import WidgetKit
import SwiftUI

struct WidgetStrings {
    static let widgetName = "Weathra"
    static let widgetDescription = "Dışarı çıkma kararınızı anlık olarak görün."
    static let widgetNoData = "Veri yok"
    static let widgetOpenApp = "Uygulamayı aç"
    static let decisionGood = "Dışarı çıkabilirsiniz"
    static let decisionBad = "Dışarı çıkmanızı önermiyoruz"
    static let decisionModerate = "Dikkatli olun"
    static let outfitLightAndComfortable = "Hafif ve rahat"
    static let activityRunning = "Koşu"
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
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date().addingTimeInterval(7200)
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
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }

                    Spacer()

                    if let bestWindow = recommendation.bestOutdoorWindow {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            Text(bestWindow.shortDisplayText)
                                .font(.caption2.weight(.bold))
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(WidgetStrings.widgetNoData)
                        .font(.caption.weight(.semibold))
                    Text(WidgetStrings.widgetOpenApp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
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