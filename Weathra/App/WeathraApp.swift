import SwiftData
import SwiftUI
import os

@main
struct WeathraApp: App {
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

        do {
            let fallbackConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(
                for: schema,
                configurations: [fallbackConfig]
            )
        } catch {
            fatalError("Failed to create fallback ModelContainer: \(error)")
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
            .task { AdsManager.configure() }
            .onChange(of: scenePhase) { _, phase in
                handleScenePhaseChange(phase)
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