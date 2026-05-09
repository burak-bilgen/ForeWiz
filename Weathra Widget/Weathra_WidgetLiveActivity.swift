//
//  Weathra_WidgetLiveActivity.swift
//  Weathra Widget
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Weathra_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var temperature: Int
        var conditionSymbol: String
        var score: Int
        var decision: String
        var locationName: String

        var decisionColor: Color {
            switch decision {
            case "good": return Color(red: 0.3, green: 0.85, blue: 0.6)
            case "moderate": return Color(red: 1.0, green: 0.7, blue: 0.3)
            default: return Color(red: 1.0, green: 0.4, blue: 0.4)
            }
        }

        var decisionText: String {
            switch decision {
            case "good": return "Dışarı çık"
            case "moderate": return "Dikkatli ol"
            case "risky": return "Riskli"
            case "avoid": return "Kaçın"
            default: return "Bilinmiyor"
            }
        }
    }

    var startDate: Date
    var locationName: String
}

struct Weathra_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Weathra_WidgetAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.state.conditionSymbol)
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                        Text("\(context.state.temperature)°")
                            .font(.system(size: 28, weight: .thin, design: .rounded))
                    }
                    .foregroundStyle(.primary)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.score)/100")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(context.state.decisionColor)
                        Text(context.state.decisionText)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(context.attributes.locationName)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: context.state.conditionSymbol)
                    .font(.system(size: 14))
                    .symbolRenderingMode(.hierarchical)
            } compactTrailing: {
                Text("\(context.state.temperature)°")
                    .font(.system(size: 14, weight: .medium))
            } minimal: {
                Image(systemName: context.state.conditionSymbol)
                    .font(.system(size: 12))
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<Weathra_WidgetAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text(context.attributes.locationName)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: context.state.conditionSymbol)
                        .font(.system(size: 36))
                        .symbolRenderingMode(.hierarchical)
                    Text("\(context.state.temperature)°")
                        .font(.system(size: 44, weight: .thin, design: .rounded))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(context.state.decisionColor)
                        .frame(width: 10, height: 10)
                    Text(context.state.decisionText)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text("Dışarı çıkma skoru")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Text("\(context.state.score)/100")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(context.state.decisionColor)
            }
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground))
    }
}

extension Weathra_WidgetAttributes {
    static var preview: Weathra_WidgetAttributes {
        Weathra_WidgetAttributes(startDate: Date(), locationName: "Antalya")
    }
}

extension Weathra_WidgetAttributes.ContentState {
    static var goodWeather: Weathra_WidgetAttributes.ContentState {
        Weathra_WidgetAttributes.ContentState(
            temperature: 26,
            conditionSymbol: "sun.max.fill",
            score: 92,
            decision: "good",
            locationName: "Antalya"
        )
    }

    static var rainyWeather: Weathra_WidgetAttributes.ContentState {
        Weathra_WidgetAttributes.ContentState(
            temperature: 18,
            conditionSymbol: "cloud.rain.fill",
            score: 45,
            decision: "risky",
            locationName: "İstanbul"
        )
    }
}

#Preview("Notification", as: .content, using: Weathra_WidgetAttributes.preview) {
   Weathra_WidgetLiveActivity()
} contentStates: {
    Weathra_WidgetAttributes.ContentState.goodWeather
    Weathra_WidgetAttributes.ContentState.rainyWeather
}