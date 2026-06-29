import SwiftUI
import WidgetKit

private func formattedTemp(_ temp: Double) -> String {
    "\(Int(round(temp)))°"
}

private func scoreColor(_ score: Int) -> Color {
    switch score {
    case 80...100: Color(red: 0.18, green: 0.70, blue: 0.48)
    case 60..<80: Color(red: 0.25, green: 0.60, blue: 1.0)
    case 40..<60: Color(red: 0.95, green: 0.62, blue: 0.18)
    default: Color(red: 0.92, green: 0.28, blue: 0.32)
    }
}

private func timeAgoText(from date: Date) -> String {
    let interval = -date.timeIntervalSinceNow
    if interval < 60 { return WidgetL10n.text("widget_just_now") }
    let minutes = Int(interval / 60)
    if minutes < 60 { return String(format: WidgetL10n.text("widget_min_ago"), minutes) }
    return ""
}

private func glassBackground() -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)

        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.03),
                        .clear,
                        .white.opacity(0.01),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.10),
                        .white.opacity(0.02),
                        .white.opacity(0.05),
                        .clear,
                        .white.opacity(0.03),
                        .white.opacity(0.07)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

private struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 32
    var lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Circle()
                .stroke(scoreColor(score).opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(scoreColor(score), style: .init(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: scoreColor(score).opacity(0.35), radius: 3)
            Text("\(score)")
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(width: size, height: size)
    }
}

private struct EmptyPlaceholderView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(.white.opacity(0.3))

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Text(message)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StaleBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 8, weight: .bold))
            Text(WidgetL10n.text("widget_stale_title"))
                .font(.system(size: 8, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.5))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(Capsule())
    }
}

struct ForeWizWidgetMediumView: View {
    let entry: ForeWizWidgetEntry

    var body: some View {
        if let data = entry.widgetData {
            HStack(spacing: 0) {

                currentPanel(data: data)

                Divider()
                    .frame(width: 1)
                    .overlay(.white.opacity(0.12))

                forecastPanel(data: data)
            }
            .containerBackground(for: .widget) {
                glassBackground()
            }
            .widgetURL(URL(string: "forewiz://home"))
            .overlay(alignment: .topTrailing) {
                if entry.emptyState == .staleData {
                    StaleBadge()
                        .padding(8)
                }
            }
        } else {
            emptyMediumView(for: entry.emptyState)
                .containerBackground(for: .widget) {
                    glassBackground()
                }
                .widgetURL(URL(string: "forewiz://home"))
        }
    }

    @ViewBuilder
    private func emptyMediumView(for state: WidgetEmptyState?) -> some View {
        switch state {
        case .awaitingFirstData, .none:
            EmptyPlaceholderView(
                icon: "cloud.sun.fill",
                title: WidgetL10n.text("widget_waiting_title"),
                message: WidgetL10n.text("widget_waiting_msg")
            )

        case .configurationError:
            EmptyPlaceholderView(
                icon: "gearshape.fill",
                title: WidgetL10n.text("widget_config_error"),
                message: WidgetL10n.text("widget_config_error_msg")
            )

        case .corruptedData:
            EmptyPlaceholderView(
                icon: "arrow.triangle.2.circlepath",
                title: WidgetL10n.text("widget_corrupted_title"),
                message: WidgetL10n.text("widget_corrupted_msg")
            )

        case .staleData:

            EmptyPlaceholderView(
                icon: "clock.fill",
                title: WidgetL10n.text("widget_stale_title"),
                message: WidgetL10n.text("widget_stale_msg")
            )
        }
    }

    private func currentPanel(data: WeatherWidgetData) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            Text(data.locationName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: data.currentConditionSymbol)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.multicolor)

                Text(formattedTemp(data.currentTemperature))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
            }

            Text(data.currentConditionDescription)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                ScoreRing(score: data.outdoorScore, size: 30, lineWidth: 3)

                VStack(alignment: .leading, spacing: 1) {
                    Text(WidgetL10n.text("widget_outdoor_label"))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(WidgetL10n.text("widget_score_label"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer(minLength: 0)

                let ago = timeAgoText(from: data.lastUpdated)
                if !ago.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 7))
                        Text(ago)
                    }
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func forecastPanel(data: WeatherWidgetData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(WidgetL10n.text("widget_forecast_title"))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
                .padding(.bottom, 8)

            ForEach(Array(data.dailyForecasts.prefix(4).enumerated()), id: \.element.id) { index, day in
                HStack(spacing: 6) {

                    Text(day.isToday ? WidgetL10n.text("widget_today") : String(day.dayName.prefix(3)))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 30, alignment: .leading)

                    Image(systemName: day.conditionSymbol)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 14)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.08))
                                .frame(height: 3)
                            Capsule()
                                .fill(scoreColor(day.outdoorScore))
                                .frame(width: max(geo.size.width * CGFloat(day.outdoorScore) / 100.0, 2), height: 3)
                        }
                    }
                    .frame(height: 3)

                    Text(formattedTemp(day.lowTemp))
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 26, alignment: .trailing)

                    Text(formattedTemp(day.highTemp))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 26, alignment: .trailing)
                }

                if index < min(data.dailyForecasts.count, 4) - 1 {
                    Divider()
                        .overlay(.white.opacity(0.06))
                        .padding(.vertical, 3)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ForeWizWidgetSmallView: View {
    let entry: ForeWizWidgetEntry

    var body: some View {
        if let data = entry.widgetData {
            VStack(spacing: 0) {

                Text(data.locationName)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: data.currentConditionSymbol)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.multicolor)

                Text(formattedTemp(data.currentTemperature))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(data.currentConditionDescription)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    ScoreRing(score: data.outdoorScore, size: 26, lineWidth: 2.5)
                    Text(WidgetL10n.text("widget_score_label"))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                glassBackground()
            }
            .widgetURL(URL(string: "forewiz://home"))
            .overlay(alignment: .topTrailing) {
                if entry.emptyState == .staleData {
                    StaleBadge()
                        .padding(6)
                }
            }
        } else {
            emptySmallView(for: entry.emptyState)
                .containerBackground(for: .widget) {
                    glassBackground()
                }
                .widgetURL(URL(string: "forewiz://home"))
        }
    }

    @ViewBuilder
    private func emptySmallView(for state: WidgetEmptyState?) -> some View {
        switch state {
        case .awaitingFirstData, .none:
            EmptyPlaceholderView(
                icon: "cloud.sun.fill",
                title: WidgetL10n.text("widget_waiting_title"),
                message: WidgetL10n.text("widget_waiting_msg")
            )

        case .configurationError:
            EmptyPlaceholderView(
                icon: "gearshape.fill",
                title: WidgetL10n.text("widget_config_error"),
                message: WidgetL10n.text("widget_config_error_msg")
            )

        case .corruptedData:
            EmptyPlaceholderView(
                icon: "arrow.triangle.2.circlepath",
                title: WidgetL10n.text("widget_corrupted_title"),
                message: WidgetL10n.text("widget_corrupted_msg")
            )

        case .staleData:
            EmptyPlaceholderView(
                icon: "clock.fill",
                title: WidgetL10n.text("widget_stale_title"),
                message: WidgetL10n.text("widget_stale_msg")
            )
        }
    }
}

struct ForeWizWidgetInlineView: View {
    let entry: ForeWizWidgetEntry

    var body: some View {
        if let data = entry.widgetData {
            HStack(spacing: 4) {
                Image(systemName: data.currentConditionSymbol)
                Text(formattedTemp(data.currentTemperature))
                    .fontWeight(.bold)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(data.currentConditionDescription)
            }
            .widgetURL(URL(string: "forewiz://home"))
        } else {
            Text("--°")
        }
    }
}

struct ForeWizWidgetCircularView: View {
    let entry: ForeWizWidgetEntry

    var body: some View {
        if let data = entry.widgetData {
            ZStack {
                AccessoryWidgetBackground()
                ScoreRing(score: data.outdoorScore, size: 48, lineWidth: 4)
            }
            .widgetURL(URL(string: "forewiz://home"))
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Text("--")
                    .font(.headline)
            }
        }
    }
}

struct ForeWizWidgetRectangularView: View {
    let entry: ForeWizWidgetEntry

    var body: some View {
        if let data = entry.widgetData {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: data.currentConditionSymbol)
                        .font(.system(size: 14))
                    Text(data.locationName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Spacer()
                    Text(formattedTemp(data.currentTemperature))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }

                HStack(spacing: 6) {
                    Text(data.currentConditionDescription)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)

                    Spacer()

                    ScoreRing(score: data.outdoorScore, size: 22, lineWidth: 2.5)
                    Text(WidgetL10n.text("widget_outdoor_label"))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .widgetURL(URL(string: "forewiz://home"))
        } else {
            VStack(alignment: .leading) {
                Text(WidgetL10n.text("widget_name"))
                    .font(.headline)
                Text(WidgetL10n.text("widget_waiting_msg"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ForeWizWidgetEntryView: View {
    var entry: ForeWizWidgetProvider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            ForeWizWidgetSmallView(entry: entry)
        case .systemMedium, .systemLarge, .systemExtraLarge:
            ForeWizWidgetMediumView(entry: entry)
        case .accessoryInline:
            ForeWizWidgetInlineView(entry: entry)
        case .accessoryCircular:
            ForeWizWidgetCircularView(entry: entry)
        case .accessoryRectangular:
            ForeWizWidgetRectangularView(entry: entry)
        @unknown default:
            ForeWizWidgetMediumView(entry: entry)
        }
    }
}
