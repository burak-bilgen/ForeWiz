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

        WizPathKitL10n.provider = ForeWizL10nProvider()

    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            UserPreferencesModel.self,
            WeatherSnapshotModel.self,
            JournalEntryModel.self
        ])

        do {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            let storeDir = config.url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true,
                attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])

            try? (storeDir as NSURL).setResourceValue(
                FileProtectionType.completeUntilFirstUserAuthentication,
                forKey: .fileProtectionKey
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [config]
            )

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

            let minimalSchema = Schema([UserPreferencesModel.self])
            let minimalConfig = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
            if let minimal = try? ModelContainer(for: minimalSchema, configurations: [minimalConfig]) {
                return minimal
            }
            AppLogger.persistence.critical("Unable to create ANY SwiftData ModelContainer - app cannot function")

            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)

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
        case .inactive:
            AppLifecycleManager.shared.applicationWillResignActive()
        case .background:
            AppLifecycleManager.shared.applicationDidEnterBackground()
        @unknown default:
            break
        }
    }
}
