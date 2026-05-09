//
//  Weathra_Widget.swift
//  Weathra Widget
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(
            date: Date(),
            temperature: 24,
            condition: "clear",
            score: 85,
            decision: .good,
            locationName: "Antalya"
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> WeatherEntry {
        await getEntry(for: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<WeatherEntry> {
        let entry = await getEntry(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func getEntry(for configuration: ConfigurationAppIntent) async -> WeatherEntry {
        let userDefaults = UserDefaults(suiteName: "group.weathra")
        
        if let data = userDefaults?.data(forKey: "weathra_latest_recommendation"),
           let payload = try? JSONDecoder().decode(WidgetWeatherPayload.self, from: data) {
            
            return WeatherEntry(
                date: Date(),
                temperature: payload.temperature,
                condition: payload.conditionSymbol,
                score: payload.score,
                decision: OutdoorDecision(rawValue: payload.decision) ?? .moderate,
                locationName: payload.locationName
            )
        }
        
        return WeatherEntry(
            date: Date(),
            temperature: 22,
            condition: "cloud.sun",
            score: 72,
            decision: .moderate,
            locationName: "Konum yok"
        )
    }
}

struct WeatherEntry: TimelineEntry {
    let date: Date
    let temperature: Int
    let condition: String
    let score: Int
    let decision: OutdoorDecision
    let locationName: String

    var decisionColor: Color {
        switch decision {
        case .good: return Color(red: 0.3, green: 0.85, blue: 0.6)
        case .moderate: return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .risky, .avoid: return Color(red: 1.0, green: 0.4, blue: 0.4)
        }
    }

    var decisionText: String {
        switch decision {
        case .good: return "Dışarı çık"
        case .moderate: return "Dikkatli ol"
        case .risky: return "Riskli"
        case .avoid: return "Dışarı çıkma"
        }
    }
}

struct Weathra_WidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.condition)
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(entry.temperature)°")
                    .font(.system(size: 28, weight: .thin, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(entry.decisionColor)
                    .frame(width: 8, height: 8)
                Text(entry.decisionText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(entry.score)/100")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text(entry.locationName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
                
                HStack(alignment: .top) {
                    Image(systemName: entry.condition)
                        .font(.system(size: 40))
                        .symbolRenderingMode(.hierarchical)
                    Text("\(entry.temperature)°")
                        .font(.system(size: 42, weight: .thin, design: .rounded))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(entry.decisionColor)
                        .frame(width: 10, height: 10)
                    Text(entry.decisionText)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text("Dışarı çıkma skoru")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Text("\(entry.score)/100")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.decisionColor)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct Weathra_Widget: Widget {
    let kind: String = "Weathra_Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Weathra_WidgetEntryView(entry: entry)
        }
    }
}

struct WidgetWeatherPayload: Codable {
    let temperature: Int
    let conditionSymbol: String
    let score: Int
    let decision: String
    let locationName: String
}

enum OutdoorDecision: String, Codable {
    case good
    case moderate
    case risky
    case avoid
}

#Preview(as: .systemSmall) {
    Weathra_Widget()
} timeline: {
    WeatherEntry(date: .now, temperature: 24, condition: "sun.max.fill", score: 92, decision: .good, locationName: "Antalya")
}

#Preview(as: .systemMedium) {
    Weathra_Widget()
} timeline: {
    WeatherEntry(date: .now, temperature: 18, condition: "cloud.rain.fill", score: 45, decision: .risky, locationName: "İstanbul")
}