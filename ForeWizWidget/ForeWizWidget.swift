import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), temperature: "21°", condition: "Clear", high: "26°", low: "14°", symbol: "sun.max.fill")
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        let entry = WeatherEntry(date: Date(), temperature: "21°", condition: "Clear", high: "26°", low: "14°", symbol: "sun.max.fill")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let entry = WeatherEntry(date: Date(), temperature: "21°", condition: "Clear", high: "26°", low: "14°", symbol: "sun.max.fill")
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct WeatherEntry: TimelineEntry {
    let date: Date
    let temperature: String
    let condition: String
    let high: String
    let low: String
    let symbol: String
}

struct ForeWizWidgetEntryView: View {
    var entry: WeatherEntry
    @Environment(\.widgetFamily) var family

    private var gradientColors: [Color] {
        let s = entry.symbol.lowercased()
        if s.contains("sun") || s.contains("clear") {
            return [Color(red: 1.0, green: 0.6, blue: 0.1), Color(red: 0.9, green: 0.35, blue: 0.05), Color(red: 0.2, green: 0.3, blue: 0.6)]
        }
        if s.contains("rain") || s.contains("drizzle") {
            return [Color(red: 0.2, green: 0.4, blue: 0.7), Color(red: 0.15, green: 0.25, blue: 0.5), Color(red: 0.1, green: 0.15, blue: 0.3)]
        }
        if s.contains("cloud") {
            return [Color(red: 0.4, green: 0.45, blue: 0.55), Color(red: 0.25, green: 0.3, blue: 0.4), Color(red: 0.15, green: 0.18, blue: 0.25)]
        }
        if s.contains("snow") || s.contains("sleet") {
            return [Color(red: 0.7, green: 0.8, blue: 0.95), Color(red: 0.5, green: 0.6, blue: 0.8), Color(red: 0.3, green: 0.4, blue: 0.6)]
        }
        if s.contains("storm") || s.contains("thunder") {
            return [Color(red: 0.5, green: 0.2, blue: 0.8), Color(red: 0.3, green: 0.1, blue: 0.5), Color(red: 0.1, green: 0.05, blue: 0.2)]
        }
        return [Color(red: 0.25, green: 0.48, blue: 0.92), Color(red: 0.15, green: 0.32, blue: 0.75), Color(red: 0.04, green: 0.06, blue: 0.14)]
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        default:
            systemView
        }
    }

    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: entry.symbol)
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
                Text(entry.temperature)
                    .font(.system(size: 16, weight: .medium))
            }
        }
    }

    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.symbol)
                    .font(.system(size: 12))
                Text(entry.temperature)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            Text(entry.condition)
                .font(.system(size: 11))
            HStack(spacing: 8) {
                Label(entry.high, systemImage: "arrow.up")
                    .font(.system(size: 10))
                Label(entry.low, systemImage: "arrow.down")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.secondary)
        }
    }

    private var systemView: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: entry.symbol)
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.9))

                Text(entry.temperature)
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 2)

                Text(entry.condition)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(L10n.text("widget.high_label")) \(entry.high)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.7))

                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(L10n.text("widget.low_label")) \(entry.low)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 8)
            }
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
        .configurationDisplayName("ForeWiz Weather")
        .description("Current weather at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct ForeWizWidget_Previews: PreviewProvider {
    static var previews: some View {
        ForeWizWidgetEntryView(entry: WeatherEntry(date: Date(), temperature: "24°", condition: "Sunny", high: "28°", low: "16°", symbol: "sun.max.fill"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
