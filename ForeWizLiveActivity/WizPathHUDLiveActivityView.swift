import SwiftUI
import WidgetKit
import ActivityKit
import WizPathKit

@available(iOS 18.0, *)
struct ForeWizLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WizPathHUDLiveActivityAttributes.self) { context in
            // Lock Screen / Banner view
            WizPathHUDLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    leadingView(context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    trailingView(context)
                }
                DynamicIslandExpandedRegion(.center) {
                    centerView(context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    bottomView(context)
                }
            } compactLeading: {
                compactLeadingView(context)
            } compactTrailing: {
                compactTrailingView(context)
            } minimal: {
                minimalView(context)
            }
        }
        .configurationDisplayName("Route HUD")
        .description("Shows active route safety score and ETA")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    // MARK: - Compact Views

    private func compactLeadingView(_ context: ActivityViewContext<WizPathHUDLiveActivityAttributes>) -> some View {
        Image(systemName: travelModeIcon(for: context.attributes.travelModeRaw))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .transition(.opacity)
    }

    private func compactTrailingView(_ context: ActivityViewContext<WizPathHUDLiveActivityAttributes>) -> some View {
        Text("\(context.state.safetyScore)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(safetyColor(context.state.safetyScore))
    }

    private func minimalView(_ context: ActivityViewContext<WizPathHUDLiveActivityAttributes>) -> some View {
        ZStack {
            Circle()
                .stroke(safetyColor(context.state.safetyScore).opacity(0.3), lineWidth: 2)
            Circle()
                .trim(from: 0, to: CGFloat(context.state.safetyScore) / 100)
                .stroke(safetyColor(context.state.safetyScore), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(context.state.safetyScore)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(2)
    }

    // MARK: - Expanded Views

    private func leadingView(_ context: ActivityViewContext<WizPathHUDLiveActivityAttributes>) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(hazardColor(context.state.hazardCount))
            Text("\(context.state.hazardCount)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func trailingView(_ context: ActivityViewContext<WizPathHUDLiveActivityAttributes>) -> some View {
        VStack(spacing: 2) {
            Text("ETA")
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            Text(context.state.estimatedArrival, style: .time)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func centerView(_ context: ActivityViewContext<WizPathHUDLiveActivityAttributes>) -> some View {
        HStack(spacing: 6) {
            Text(context.attributes.routeOriginName)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)

            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))

            Text(context.attributes.routeDestinationName)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }

    private func bottomView(_ context: ActivityViewContext<WizPathHUDLiveActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            // Safety score ring
            ZStack {
                Circle()
                    .stroke(safetyColor(context.state.safetyScore).opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                Circle()
                    .trim(from: 0, to: CGFloat(context.state.safetyScore) / 100)
                    .stroke(safetyColor(context.state.safetyScore), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                Text("\(context.state.safetyScore)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(safetyColor(context.state.safetyScore))
            }

            // Route status
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.routeRiskLabel)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                if let nextStop = context.state.nextSafeStopName {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.4))
                        Text(nextStop)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Weather icon
            Image(systemName: context.state.weatherConditionSymbol)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Helpers

    private func travelModeIcon(for rawValue: String) -> String {
        switch rawValue {
        case "car": return "car.fill"
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "transit": return "bus.fill"
        default: return "car.fill"
        }
    }

    private func safetyColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return Color.green
        case 60..<80: return Color.yellow
        case 40..<60: return Color.orange
        default: return Color.red
        }
    }

    private func hazardColor(_ count: Int) -> Color {
        count == 0 ? Color.green : count <= 3 ? Color.yellow : Color.red
    }
}

// MARK: - Lock Screen / Banner View

struct WizPathHUDLiveActivityView: View {
    let context: ActivityViewContext<WizPathHUDLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(safetyColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: travelModeIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(safetyColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(context.attributes.routeOriginName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                    Text(context.attributes.routeDestinationName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .lineLimit(1)

                HStack(spacing: 8) {
                    Label(context.state.estimatedArrival, style: .time)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    if context.state.hazardCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                            Text("\(context.state.hazardCount)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.yellow)
                    }
                }
            }

            Spacer()

            // Score
            ZStack {
                Circle()
                    .stroke(safetyColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: CGFloat(context.state.safetyScore) / 100)
                    .stroke(safetyColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(context.state.safetyScore)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("safe")
                        .font(.system(size: 7, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .environment(\.colorScheme, .dark)
    }

    private var travelModeIcon: String {
        switch context.attributes.travelModeRaw {
        case "car": return "car.fill"
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "transit": return "bus.fill"
        default: return "car.fill"
        }
    }

    private var safetyColor: Color {
        switch context.state.safetyScore {
        case 80...100: return Color.green
        case 60..<80: return Color.yellow
        case 40..<60: return Color.orange
        default: return Color.red
        }
    }
}
