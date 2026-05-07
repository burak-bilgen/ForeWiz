import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    let repository = SharedWidgetRepository(suiteName: "group.weathra")

    func placeholder(in context: Context) -> DailyDecisionEntry {
        DailyDecisionEntry(date: Date(), recommendation: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyDecisionEntry) -> Void) {
        let recommendation = try? repository.loadLatest()
        let entry = DailyDecisionEntry(date: Date(), recommendation: recommendation ?? .placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let recommendation = try? repository.loadLatest()
        let entry = DailyDecisionEntry(date: Date(), recommendation: recommendation)
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date().addingTimeInterval(7200)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

struct DailyDecisionEntry: TimelineEntry {
    let date: Date
    let recommendation: DailyRecommendation?
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
                    Text(L10n.text( "widget_no_data"))
                        .font(.caption.weight(.semibold))
                    Text(L10n.text( "widget_open_app"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct ScoreRingViewWidget: View {
    let score: WeatherScore

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(score.rawValue) / 100)
                .stroke(tintColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(score.rawValue)")
                .font(.system(.caption2, design: .rounded, weight: .bold))
        }
        .frame(width: 32, height: 32)
    }

    private var tintColor: Color {
        switch score.rawValue {
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
        .configurationDisplayName(L10n.text( "widget_name"))
        .description(L10n.text( "widget_description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension DailyRecommendation {
    static var placeholder: DailyRecommendation {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now
        let endTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now

        return DailyRecommendation(
            generatedAt: now,
            outdoorDecision: .good,
            outdoorScore: WeatherScore(rawValue: 85),
            bestOutdoorWindow: TimeWindow(start: startTime, end: endTime),
            bestActivityWindows: [],
            avoidWindows: [],
            outfit: OutfitRecommendation(
                title: L10n.text( "outfit_light_and_comfortable"),
                items: [L10n.text( "activity_running")],
                accessories: [],
                warning: nil
            ),
            risks: [],
            summaryText: L10n.text( "decision_good"),
            explanation: "85/100"
        )
    }
}
