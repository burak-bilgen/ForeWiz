import OSLog
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
        
        // Initialize ad system early
        Task {
            await AdManager.shared.initialize()
            AdConsentManager.shared.updateConsentStatus()
            
            // Initialize AdMob SDK
            await AdMobIntegration.shared.initializeSDK()
        }
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

            // 🔒 Pre-apply NSFileProtectionComplete to the store's parent directory
            // BEFORE the ModelContainer opens the SQLite file. This ensures that
            // any files created by SwiftData inherit the directory's protection.
            let storeDir = config.url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true,
                attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUnlessOpen])
            // Also apply protection attribute on the directory via NSURL path-based API
            try? (storeDir as NSURL).setResourceValue(
                FileProtectionType.completeUnlessOpen,
                forKey: .fileProtectionKey
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [config]
            )

            // 🔐 Also set protection directly on the store file (belt-and-suspenders).
            // This ensures the file is protected even if directory inheritance doesn't work.
            if let storeFileURL = container.configurations.first?.url {
                try? (storeFileURL as NSURL).setResourceValue(
                    FileProtectionType.completeUnlessOpen,
                    forKey: .fileProtectionKey
                )
                try? FileManager.default.setAttributes(
                    [FileAttributeKey.protectionKey: FileProtectionType.completeUnlessOpen],
                    ofItemAtPath: storeFileURL.path
                )
            }

            return container
        } catch {
            AppLogger.persistence.error("Persistent ModelContainer failed: \(error.localizedDescription, privacy: .private)")
        }

        AppLogger.persistence.error("Persistent ModelContainer failed - falling back to in-memory")
        do {
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [fallbackConfig])
        } catch {
            AppLogger.persistence.error("Fallback ModelContainer also failed: \(error.localizedDescription, privacy: .private)")
            // Last resort: minimal in-memory container with empty schema
            let minimalSchema = Schema([UserPreferencesModel.self])
            let minimalConfig = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
            if let minimal = try? ModelContainer(for: minimalSchema, configurations: [minimalConfig]) {
                return minimal
            }
            AppLogger.persistence.critical("Unable to create ANY SwiftData ModelContainer - app cannot function")
            // Graceful crash - app cannot function without persistence
            fatalError("ForeWiz requires a working data store to operate")
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
            AdPlacementStrategy.shared.sessionStarted()
            
            // Refresh expired ad caches periodically
            Task {
                await AdManager.shared.refreshExpiredCaches()
            }
            
            // Show app open ad at natural transition point
            if AdPlacementStrategy.shared.shouldShowAppOpen(),
               let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?
                .windows
                .first?
                .rootViewController {
                _ = AdMobIntegration.shared.showAppOpenAd(
                    from: rootVC,
                    onDismiss: {}
                )
            }
        case .inactive:
            AppLifecycleManager.shared.applicationWillResignActive()
        case .background:
            AppLifecycleManager.shared.applicationDidEnterBackground()
            AdPlacementStrategy.shared.sessionEnded()
        @unknown default:
            break
        }
    }
}
