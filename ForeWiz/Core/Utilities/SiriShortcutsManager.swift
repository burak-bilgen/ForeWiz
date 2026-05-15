import Foundation
import AppIntents
import SwiftUI
import OSLog
import WidgetKit

@available(iOS 16.0, *)
struct GetWeatherRecommendationIntent: AppIntent {
    static var title: LocalizedStringResource { "Get Weather Recommendation" }
    static var description = IntentDescription(stringLiteral: "Get personalized weather recommendation for your current location")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("GetWeatherRecommendationIntent executed")

        let container = try await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let recommendation = result.recommendation

            let decisionText: String
            switch recommendation.outdoorDecision {
            case .good:
                decisionText = L10n.text("siri_response_great_weather")
            case .moderate:
                decisionText = L10n.text("siri_response_okay_weather")
            case .risky:
                decisionText = L10n.text("siri_response_stay_inside_consider")
            case .avoid:
                decisionText = L10n.text("siri_response_stay_indoors")
            }

            let outfitItems = recommendation.outfit.items.joined(separator: ", ")
            let accessories = recommendation.outfit.accessories.isEmpty ? "" : "\(L10n.text("siri_response_outfit_accessories_prefix")) \(recommendation.outfit.accessories.joined(separator: ", "))"

            let response = "\(decisionText) \(L10n.formatted("siri_response_score_template", recommendation.outdoorScore.displayValue)). " +
                          "\(L10n.text("siri_response_outfit_prefix")) \(outfitItems). \(accessories)"

            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to get recommendation: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct GetCurrentTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource { "Get Current Temperature" }
    static var description = IntentDescription(stringLiteral: "Get the current temperature for your location")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("GetCurrentTemperatureIntent executed")

        let container = try await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let current = result.currentWeather

            let temp = Int(current.temperatureCelsius)
            let feelsLike = Int(current.apparentTemperatureCelsius)

            let response = L10n.formatted("siri_response_temp_template", String(temp), String(feelsLike))

            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to get temperature: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct GetOutfitRecommendationIntent: AppIntent {
    static var title: LocalizedStringResource { "Get Outfit Recommendation" }
    static var description = IntentDescription(stringLiteral: "Get clothing recommendations based on current weather")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("GetOutfitRecommendationIntent executed")

        let container = try await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let outfit = result.recommendation.outfit

            let items = outfit.items.joined(separator: ", ")
            let accessories = outfit.accessories.isEmpty ? "" : " \(L10n.text("siri_response_accessories_label")) \(outfit.accessories.joined(separator: ", "))."
            let warning = outfit.warning.map { " \(L10n.text("siri_response_note_label")) \($0)" } ?? ""

            let response = "\(L10n.text("siri_response_outfit_today_prefix")) \(items).\(accessories)\(warning)"

            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to get outfit: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct GetBestActivityWindowIntent: AppIntent {
    static var title: LocalizedStringResource { "Get Best Activity Window" }
    static var description = IntentDescription(stringLiteral: "Find the best time window for outdoor activities today")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Activity", description: "Type of activity you're planning")
    var activity: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("GetBestActivityWindowIntent executed for activity: \(activity ?? "any")")

        let container = try await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let windows = result.recommendation.bestActivityWindows

            guard !windows.isEmpty else {
                return .result(value: L10n.text("siri_response_no_windows"),
                              dialog: IntentDialog(stringLiteral: L10n.text("siri_response_no_windows")))
            }

            let targetActivity: ActivityType
            if let activity = activity {
                targetActivity = ActivityType.allCases.first { $0.rawValue.lowercased() == activity.lowercased() } ?? .walking
            } else {
                targetActivity = .walking
            }

            if let window = windows.first(where: { $0.activityType == targetActivity }) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short

                let startTime = formatter.string(from: window.bestWindow.start)
                let endTime = formatter.string(from: window.bestWindow.end)

                let response = L10n.formatted("siri_best_time_for_activity", targetActivity.localizedTitle, startTime, endTime, String(window.score.displayValue))

                return .result(value: response, dialog: IntentDialog(stringLiteral: response))
            } else {
                let firstWindow = windows[0]
                let formatter = DateFormatter()
                formatter.timeStyle = .short

                let startTime = formatter.string(from: firstWindow.bestWindow.start)
                let endTime = formatter.string(from: firstWindow.bestWindow.end)

                let response = L10n.formatted("siri_best_time_for_activity", firstWindow.activityType.localizedTitle, startTime, endTime, String(firstWindow.score.displayValue))

                return .result(value: response, dialog: IntentDialog(stringLiteral: response))
            }
        } catch {
            AppLogger.shortcuts.error("Failed to get activity window: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct CheckWeatherRisksIntent: AppIntent {
    static var title: LocalizedStringResource { "Check Weather Risks" }
    static var description = IntentDescription(stringLiteral: "Check for any weather warnings or risks for today")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("CheckWeatherRisksIntent executed")

        let container = try await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let risks = result.recommendation.risks

            if risks.isEmpty {
                let response = L10n.text("siri_response_no_risks")
                return .result(value: response, dialog: IntentDialog(stringLiteral: response))
            }

            let riskDescriptions = risks.map { "\($0.severity.description) \($0.type.description)" }
            let joinedRisks = riskDescriptions.joined(separator: ", ")

            let response = L10n.formatted("siri_response_risks_template", joinedRisks)

            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to check risks: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct RefreshWeatherDataIntent: AppIntent {
    static var title: LocalizedStringResource { "Refresh Weather Data" }
    static var description = IntentDescription(stringLiteral: "Fetch the latest weather data for your location")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("RefreshWeatherDataIntent executed")

        let container = try await ContainerProvider.shared.container

        do {
            _ = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: true)

            let response = L10n.text("siri_response_refreshed")
            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to refresh weather: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct ForeWizShortcuts {
    static var shortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: GetWeatherRecommendationIntent(),
                phrases: [
                    "\(.applicationName) weather recommendation",
                    "What's the weather like in \(.applicationName)",
                    "Should I go outside according to \(.applicationName)",
                    "\(.applicationName) outdoor advice"
                ],
                shortTitle: "Weather Recommendation",
                systemImageName: "cloud.sun.fill"
            ),
            AppShortcut(
                intent: GetCurrentTemperatureIntent(),
                phrases: [
                    "What's the temperature in \(.applicationName)",
                    "\(.applicationName) current temperature",
                    "How hot is it according to \(.applicationName)"
                ],
                shortTitle: "Current Temperature",
                systemImageName: "thermometer"
            ),
            AppShortcut(
                intent: GetOutfitRecommendationIntent(),
                phrases: [
                    "What should I wear according to \(.applicationName)",
                    "\(.applicationName) outfit recommendation",
                    "Clothing advice from \(.applicationName)"
                ],
                shortTitle: "Outfit Recommendation",
                systemImageName: "tshirt.fill"
            ),
            AppShortcut(
                intent: GetBestActivityWindowIntent(),
                phrases: [
                    "When should I exercise in \(.applicationName)",
                    "\(.applicationName) best time to run",
                    "When to go outside in \(.applicationName)"
                ],
                shortTitle: "Best Exercise Time",
                systemImageName: "figure.run"
            ),
            AppShortcut(
                intent: CheckWeatherRisksIntent(),
                phrases: [
                    "Are there weather warnings in \(.applicationName)",
                    "\(.applicationName) weather alerts",
                    "Any weather risks in \(.applicationName)"
                ],
                shortTitle: "Check Weather Risks",
                systemImageName: "exclamationmark.triangle.fill"
            ),
            AppShortcut(
                intent: RefreshWeatherDataIntent(),
                phrases: [
                    "Refresh \(.applicationName) data",
                    "Update weather in \(.applicationName)",
                    "Get latest weather from \(.applicationName)"
                ],
                shortTitle: "Refresh Weather",
                systemImageName: "arrow.clockwise"
            )
        ]
    }
}

extension RiskLevel {
    var description: String {
        switch self {
        case .low: return L10n.text("risk_level_low")
        case .medium: return L10n.text("risk_level_medium")
        case .high: return L10n.text("risk_level_high")
        case .extreme: return L10n.text("risk_level_extreme")
        }
    }
}

extension WeatherRiskType {
    var description: String {
        switch self {
        case .heat: return L10n.text("risk_type_heat")
        case .cold: return L10n.text("risk_type_cold")
        case .rain: return L10n.text("risk_type_rain")
        case .storm: return L10n.text("risk_type_storm")
        case .uv: return L10n.text("risk_type_uv")
        case .wind: return L10n.text("risk_type_wind")
        case .humidity: return L10n.text("risk_type_humidity")
        case .poorComfort: return L10n.text("risk_type_poor_comfort")
        }
    }
}

@available(iOS 16.0, *)
struct SiriShortcutsSettingsView: View {
    @State private var shortcuts: [SiriShortcutInfo] = []

    var body: some View {
        List {
            Section(header: Text(L10n.text("siri_available_shortcuts"))) {
                ForEach(shortcuts) { shortcut in
                    SiriShortcutRow(shortcut: shortcut)
                }
            }

            Section(header: Text(L10n.text("siri_how_to_use"))) {
                Text(L10n.text("siri_how_to_use_desc"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("siri_example_weather"))
                    Text(L10n.text("siri_example_outfit"))
                    Text(L10n.text("siri_example_exercise"))
                    Text(L10n.text("siri_example_risks"))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.text("siri_shortcuts_title"))
        .onAppear {
            loadShortcuts()
        }
    }

    private func loadShortcuts() {
        shortcuts = [
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_weather_rec"),
                description: L10n.text("siri_intent_weather_rec_desc"),
                icon: "cloud.sun.fill",
                phrases: [L10n.text("siri_example_weather"), L10n.text("decision_good")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_temp"),
                description: L10n.text("siri_intent_temp_desc"),
                icon: "thermometer",
                phrases: [L10n.text("siri_intent_temp_title"), L10n.text("weather_current")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_outfit"),
                description: L10n.text("siri_intent_outfit_desc"),
                icon: "tshirt.fill",
                phrases: [L10n.text("siri_example_outfit"), L10n.text("what_to_wear_today")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_exercise"),
                description: L10n.text("siri_intent_exercise_desc"),
                icon: "figure.run",
                phrases: [L10n.text("siri_example_exercise"), L10n.text("notification_best_run")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_risks"),
                description: L10n.text("siri_intent_risks_desc"),
                icon: "exclamationmark.triangle.fill",
                phrases: [L10n.text("siri_example_risks"), L10n.text("alert_warning")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_refresh"),
                description: L10n.text("siri_intent_refresh_desc"),
                icon: "arrow.clockwise",
                phrases: [L10n.text("refresh_weather"), L10n.text("siri_intent_refresh_title")]
            )
        ]
    }
}

struct SiriShortcutInfo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let phrases: [String]
}

struct SiriShortcutRow: View {
    let shortcut: SiriShortcutInfo

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: shortcut.icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(shortcut.name)
                    .font(.headline)

                Text(shortcut.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(L10n.formatted("siri_try_phrase", shortcut.phrases[0]))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            Spacer()

            Image(systemName: "mic.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 16.0, *)
struct SiriShortcutsButton: View {
    var body: some View {
        NavigationLink(destination: SiriShortcutsSettingsView()) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundStyle(Color.accentColor)

                Text(L10n.text("siri_button_shortcuts"))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
