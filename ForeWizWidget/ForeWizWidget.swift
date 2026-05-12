// App Group: group.forewiz
// Shared container for Widget + Main App

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "☀️", temperature: "--°")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), emoji: "☀️", temperature: "--°")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date(), emoji: "☀️", temperature: "--°")
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
    let temperature: String
}

struct ForeWizWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.14).ignoresSafeArea()
            VStack(spacing: 8) {
                Text(entry.emoji)
                    .font(.system(size: 36))
                Text(entry.temperature)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("ForeWiz")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

@main
struct ForeWizWidget: Widget {
    let kind: String = "ForeWizWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ForeWizWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ForeWiz")
        .description("Your daily weather at a glance.")
        .supportedFamilies([.systemSmall])
    }
}
