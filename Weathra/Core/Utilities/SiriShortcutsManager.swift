import Foundation
import AppIntents
import SwiftUI
import OSLog
import SwiftData
import WidgetKit

@available(iOS 16.0, *)
struct GetWeatherRecommendationIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Weather Recommendation"
    static var description = IntentDescription("Get personalized weather recommendation for your current location")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("GetWeatherRecommendationIntent executed")

        let container = await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let recommendation = result.recommendation

            let decisionText: String
            switch recommendation.outdoorDecision {
            case .good:
                decisionText = "Great weather to go outside!"
            case .moderate:
                decisionText = "Weather is okay, but be cautious."
            case .risky:
                decisionText = "Consider staying inside today."
            case .avoid:
                decisionText = "It's best to stay indoors."
            }

            let outfitItems = recommendation.outfit.items.joined(separator: ", ")
            let accessories = recommendation.outfit.accessories.isEmpty ? "" : "Don't forget: \(recommendation.outfit.accessories.joined(separator: ", "))"

            let response = "\(decisionText) Outdoor score is \(recommendation.outdoorScore.displayValue) out of 100. " +
                          "Recommended outfit: \(outfitItems). \(accessories)"

            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to get recommendation: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct GetCurrentTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Current Temperature"
    static var description = IntentDescription("Get the current temperature for your location")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("GetCurrentTemperatureIntent executed")

        let container = await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let current = result.currentWeather

            let temp = Int(current.temperatureCelsius)
            let feelsLike = Int(current.apparentTemperatureCelsius)

            let response = "Current temperature is \(temp) degrees Celsius, feels like \(feelsLike) degrees."

            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to get temperature: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct GetOutfitRecommendationIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Outfit Recommendation"
    static var description = IntentDescription("Get clothing recommendations based on current weather")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("GetOutfitRecommendationIntent executed")

        let container = await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let outfit = result.recommendation.outfit

            let items = outfit.items.joined(separator: ", ")
            let accessories = outfit.accessories.isEmpty ? "" : " Accessories: \(outfit.accessories.joined(separator: ", "))."
            let warning = outfit.warning.map { " Note: \($0)" } ?? ""

            let response = "Today's outfit: \(items).\(accessories)\(warning)"

            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to get outfit: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct GetBestActivityWindowIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Best Time to Exercise"
    static var description = IntentDescription("Find the best time window for outdoor activities today")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Activity", description: "Type of activity you're planning")
    var activity: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("GetBestActivityWindowIntent executed for activity: \(activity ?? "any")")

        let container = await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let windows = result.recommendation.bestActivityWindows

            guard !windows.isEmpty else {
                return .result(value: "No optimal activity windows found for today.",
                              dialog: IntentDialog(stringLiteral: "No optimal activity windows found for today."))
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

                let response = "Best time for \(targetActivity.localizedTitle) is from \(startTime) to \(endTime). Score: \(window.score.displayValue) out of 100."

                return .result(value: response, dialog: IntentDialog(stringLiteral: response))
            } else {
                let firstWindow = windows[0]
                let formatter = DateFormatter()
                formatter.timeStyle = .short

                let startTime = formatter.string(from: firstWindow.bestWindow.start)
                let endTime = formatter.string(from: firstWindow.bestWindow.end)

                let response = "Best time for \(firstWindow.activityType.localizedTitle) is from \(startTime) to \(endTime). Score: \(firstWindow.score.displayValue) out of 100."

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
    static var title: LocalizedStringResource = "Check Weather Risks"
    static var description = IntentDescription("Check for any weather warnings or risks for today")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("CheckWeatherRisksIntent executed")

        let container = await ContainerProvider.shared.container

        do {
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: false)
            let risks = result.recommendation.risks

            if risks.isEmpty {
                let response = "No weather risks detected today. It's safe to go outside!"
                return .result(value: response, dialog: IntentDialog(stringLiteral: response))
            }

            let riskDescriptions = risks.map { "\($0.severity.description) \($0.type.description)" }
            let joinedRisks = riskDescriptions.joined(separator: ", ")

            let response = "Weather risks today: \(joinedRisks). Please take precautions."

            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to check risks: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct RefreshWeatherDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Weather Data"
    static var description = IntentDescription("Fetch the latest weather data for your location")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLogger.shortcuts.info("RefreshWeatherDataIntent executed")

        let container = await ContainerProvider.shared.container

        do {
            _ = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: true)

            let response = "Weather data refreshed successfully."
            return .result(value: response, dialog: IntentDialog(stringLiteral: response))
        } catch {
            AppLogger.shortcuts.error("Failed to refresh weather: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct WeathraShortcuts {
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
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        case .extreme: return "extreme"
        }
    }
}

extension WeatherRiskType {
    var description: String {
        switch self {
        case .heat: return "heat"
        case .cold: return "cold"
        case .rain: return "rain"
        case .storm: return "storm"
        case .uv: return "UV"
        case .wind: return "wind"
        case .airQuality: return "air quality"
        case .humidity: return "humidity"
        case .poorComfort: return "poor comfort"
        case .pollen: return "pollen"
        }
    }
}

@available(iOS 16.0, *)
@MainActor
final class ContainerProvider {
    static let shared = ContainerProvider()

    private var _container: DependencyContainer?

    var container: DependencyContainer {
        get async {
            if let container = _container {
                return container
            }

            let container: ModelContainer
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: false)
                container = try ModelContainer(
                    for: UserPreferencesModel.self,
                    WeatherSnapshotModel.self,
                    configurations: config
                )
            } catch {
                AppLogger.shortcuts.error("Persistent shortcut container failed: \(error.localizedDescription)")
                do {
                    let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                    container = try ModelContainer(
                        for: UserPreferencesModel.self,
                        WeatherSnapshotModel.self,
                        configurations: fallbackConfig
                    )
                } catch {
                    fatalError("Failed to create shortcut ModelContainer: \(error)")
                }
            }

            let context = ModelContext(container)
            let newContainer = DependencyContainer.live(modelContext: context)
            _container = newContainer
            return newContainer
        }
    }

    private init() {}
}

@available(iOS 16.0, *)
struct SiriShortcutsSettingsView: View {
    @State private var shortcuts: [SiriShortcutInfo] = []

    var body: some View {
        List {
            Section(header: Text("Available Shortcuts")) {
                ForEach(shortcuts) { shortcut in
                    SiriShortcutRow(shortcut: shortcut)
                }
            }

            Section(header: Text("How to Use")) {
                Text("You can use these shortcuts with Siri by saying phrases like:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• \"Hey Siri, what's the weather like in Weathra?\"")
                    Text("• \"Hey Siri, what should I wear today?\"")
                    Text("• \"Hey Siri, when should I exercise?\"")
                    Text("• \"Hey Siri, check weather risks\"")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Siri Shortcuts")
        .onAppear {
            loadShortcuts()
        }
    }

    private func loadShortcuts() {
        shortcuts = [
            SiriShortcutInfo(
                name: "Weather Recommendation",
                description: "Get personalized weather advice",
                icon: "cloud.sun.fill",
                phrases: ["What's the weather like", "Should I go outside"]
            ),
            SiriShortcutInfo(
                name: "Current Temperature",
                description: "Get current temperature and feels-like",
                icon: "thermometer",
                phrases: ["What's the temperature", "How hot is it"]
            ),
            SiriShortcutInfo(
                name: "Outfit Recommendation",
                description: "Get clothing advice for today",
                icon: "tshirt.fill",
                phrases: ["What should I wear", "Clothing advice"]
            ),
            SiriShortcutInfo(
                name: "Best Exercise Time",
                description: "Find optimal outdoor activity windows",
                icon: "figure.run",
                phrases: ["When should I exercise", "Best time to run"]
            ),
            SiriShortcutInfo(
                name: "Check Weather Risks",
                description: "Check for weather warnings",
                icon: "exclamationmark.triangle.fill",
                phrases: ["Any weather risks", "Weather alerts"]
            ),
            SiriShortcutInfo(
                name: "Refresh Weather",
                description: "Fetch latest weather data",
                icon: "arrow.clockwise",
                phrases: ["Refresh weather", "Update weather data"]
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

                Text("Try: \"\(shortcut.phrases[0])\"")
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

                Text("Siri Shortcuts")

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
