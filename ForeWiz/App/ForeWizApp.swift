import os
import SwiftData
import SwiftUI

@main
struct ForeWizApp: App {
    private let modelContainer: ModelContainer
    @State private var coordinator: AppCoordinator?
    @State private var deepLinkHandler = DeepLinkHandler()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    init() {
        modelContainer = Self.makeModelContainer()
        BackgroundRefreshManager.shared.registerTasks()
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            UserPreferencesModel.self,
            WeatherSnapshotModel.self
        ])

        do {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            return try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            AppLogger.persistence.error("Persistent ModelContainer failed: \(error.localizedDescription)")
        }

        assertionFailure("Persistent ModelContainer failed — falling back to in-memory")
        do {
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [fallbackConfig])
        } catch {
            AppLogger.persistence.error("Fallback ModelContainer also failed: \(error.localizedDescription)")
            fatalError("Unable to create ForeWiz SwiftData ModelContainer")
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let coordinator {
                    AppRootView(coordinator: coordinator, deepLinkHandler: deepLinkHandler)
                        .modelContainer(modelContainer)
                } else {
                    AppSplashView()
                        .task { initializeCoordinator() }
                }
            }
            .onOpenURL { url in
                deepLinkHandler.handle(url)
            }
            .onContinueUserActivity("refresh") { _ in
                AnalyticsManager.shared.track(.homeRefresh)
            }
            .onContinueUserActivity("settings") { _ in
                AnalyticsManager.shared.track(.settingsOpened)
            }
            .onChange(of: scenePhase) { _, phase in
                handleScenePhaseChange(phase)
            }
            .preferredColorScheme(.dark)
            .buttonStyle(.fullTapArea)
        }
    }

    @MainActor
    private func initializeCoordinator() {
        let context = modelContainer.mainContext
        #if targetEnvironment(simulator)
        coordinator = AppCoordinator(
            container: DependencyContainer.simulator(modelContext: context)
        )
        #else
        coordinator = AppCoordinator(
            container: DependencyContainer.live(modelContext: context)
        )
        #endif
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            AppLifecycleManager.shared.applicationWillEnterForeground()
            AppLifecycleManager.shared.applicationDidBecomeActive()
        case .inactive:
            AppLifecycleManager.shared.applicationWillResignActive()
        case .background:
            AppLifecycleManager.shared.applicationDidEnterBackground()
        @unknown default:
            break
        }
    }
}
