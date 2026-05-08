import SwiftData
import SwiftUI

@main
struct WeathraApp: App {
    private let modelContainer: ModelContainer
    @State private var coordinator: AppCoordinator?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            let schema = Schema([
                UserPreferencesModel.self,
                WeatherSnapshotModel.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        BackgroundRefreshManager.shared.registerTasks()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let coordinator {
                    AppRootView(coordinator: coordinator)
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
