import SwiftUI
import WidgetKit

/// Medium widget: current conditions + outdoor score + 3-day forecast mini-list.
struct ForeWizWidgetMediumView: View {
    let entry: ForeWizWidgetEntry

    var body: some View {
        if let data = entry.widgetData {
            HStack(spacing: 12) {
                // Left: current conditions + score
                currentConditionsView(data: data)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Right: mini daily forecast list
                forecastListView(data: data)
            }
            .padding(16)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.14),
                        Color(red: 0.10, green: 0.12, blue: 0.20)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        } else {
            placeholderView
        }
    }

    // MARK: - Current Conditions

    private func currentConditionsView(data: WeatherWidgetData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Location name
            Text(data.locationName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)

            Spacer(minLength: 0)

            // Condition icon + temp
            HStack(spacing: 6) {
                Image(systemName: data.currentConditionSymbol)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)

                Text(formattedTemp(data.currentTemperature))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Condition description
            Text(data.currentConditionDescription)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)

            Spacer(minLength: 0)

            // Outdoor score ring
            scoreRingView(score: data.outdoorScore)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Score Ring

    private func scoreRingView(score: Int) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(scoreColor(score).opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(scoreColor(score), style: .init(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 34, height: 34)

            Text("Outdoor")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Forecast List

    private func forecastListView(data: WeatherWidgetData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Forecast")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            ForEach(Array(data.dailyForecasts.prefix(3))) { day in
                HStack(spacing: 8) {
                    Text(day.isToday ? "Now" : day.dayName.prefix(3))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 32, alignment: .leading)

                    Image(systemName: day.conditionSymbol)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 16)

                    Text(formattedTemp(day.lowTemp))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.1))
                                .frame(height: 4)
                            Capsule()
                                .fill(scoreColor(day.outdoorScore))
                                .frame(width: geo.size.width * CGFloat(day.outdoorScore) / 100.0, height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text(formattedTemp(day.highTemp))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.3))
            Text("ForeWiz")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            Text("Open the app to load weather data.")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    Color(red: 0.10, green: 0.12, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Helpers

    private func formattedTemp(_ temp: Double) -> String {
        "\(Int(round(temp)))°"
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: .green
        case 60..<80: Color(red: 0.35, green: 0.68, blue: 1.0)
        case 40..<60: Color(red: 0.95, green: 0.62, blue: 0.18)
        default: Color(red: 0.92, green: 0.28, blue: 0.32)
        }
    }
}

/// Small widget: current condition + outdoor score.
struct ForeWizWidgetSmallView: View {
    let entry: ForeWizWidgetEntry

    var body: some View {
        if let data = entry.widgetData {
            VStack(spacing: 8) {
                Image(systemName: data.currentConditionSymbol)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)

                Text(formattedTemp(data.currentTemperature))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(data.currentConditionDescription)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)

                scoreRingCompact(score: data.outdoorScore)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.14),
                        Color(red: 0.10, green: 0.12, blue: 0.20)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        } else {
            placeholderSmall
        }
    }

    private func scoreRingCompact(score: Int) -> some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(scoreColor(score).opacity(0.2), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(scoreColor(score), style: .init(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)
        }
    }

    private var placeholderSmall: some View {
        VStack(spacing: 6) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.3))
            Text("ForeWiz")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    Color(red: 0.10, green: 0.12, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func formattedTemp(_ temp: Double) -> String {
        "\(Int(round(temp)))°"
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: .green
        case 60..<80: Color(red: 0.35, green: 0.68, blue: 1.0)
        case 40..<60: Color(red: 0.95, green: 0.62, blue: 0.18)
        default: Color(red: 0.92, green: 0.28, blue: 0.32)
        }
    }
}

// MARK: - Widget Configuration

struct ForeWizWidgetEntryView: View {
    var entry: ForeWizWidgetProvider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            ForeWizWidgetSmallView(entry: entry)
        default:
            ForeWizWidgetMediumView(entry: entry)
        }
    }
}
