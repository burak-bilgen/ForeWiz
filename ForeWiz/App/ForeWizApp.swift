import OSLog
import SwiftData
import SwiftUI
import WizPathKit

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
        
        // Set up WizPathKit localization bridge
        WizPathKitL10n.provider = ForeWizL10nProvider()
        
        // Initialize consent before the ad SDK makes any request.
        // The sequence matters: ATT must be requested before any ad SDK
        // initialization to comply with Guideline 2.1 (App Store review).
        Task { @MainActor in
            // 1. Check & request App Tracking Transparency permission FIRST.
            //    On first launch this shows the ATT dialog automatically.
            //    On subsequent launches it returns the cached status silently.
            AdConsentManager.shared.updateConsentStatus()
            _ = await AdConsentManager.shared.requestTrackingPermission()

            // 2. Only after ATT response, proceed with UMP (GDPR) & AdMob SDK init.
            await AdConsentManager.shared.prepareConsentIfNeeded()
            await AdMobIntegration.shared.initializeSDK()
            await AdManager.shared.initialize()
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

            // 🔒 Pre-apply NSFileProtectionCompleteUntilFirstUserAuthentication to the store's parent directory
            // BEFORE the ModelContainer opens the SQLite file. This ensures that
            // any files created by SwiftData inherit the directory's protection.
            let storeDir = config.url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true,
                attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            // Also apply protection attribute on the directory via NSURL path-based API
            try? (storeDir as NSURL).setResourceValue(
                FileProtectionType.completeUntilFirstUserAuthentication,
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
                    FileProtectionType.completeUntilFirstUserAuthentication,
                    forKey: .fileProtectionKey
                )
                try? FileManager.default.setAttributes(
                    [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
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
            // Last resort: return a container with minimal in-memory store.
            // If this also fails, SwiftData itself is fundamentally broken on this device.
            // We return a dummy container and let the app show a degraded state.
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            // We must return something – SwiftUI requires a container.
            return try! ModelContainer(for: UserPreferencesModel.self, configurations: fallbackConfig)
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
                EventLogger.shared.track(.homeRefresh)
            }
            .onContinueUserActivity("settings") { _ in
                EventLogger.shared.track(.settingsOpened)
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
                if AdConsentManager.shared.canServeAds {
                    await AdManager.shared.refreshExpiredCaches()
                }
            }
            
            // Show app open ad at natural transition point
            if AdConsentManager.shared.canServeAds,
               AdPlacementStrategy.shared.shouldShowAppOpen(),
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
