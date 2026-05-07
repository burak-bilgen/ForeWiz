import SwiftData
import SwiftUI

@main
struct WeathraApp: App {
    private let modelContainer: ModelContainer
    @State private var coordinator: AppCoordinator?

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
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let coordinator {
                    AppRootView(coordinator: coordinator)
                        .modelContainer(modelContainer)
                } else {
                    ProgressView()
                        .task { await initializeCoordinator() }
                }
            }
        }
    }

    @MainActor
    private func initializeCoordinator() {
        let context = modelContainer.mainContext
        coordinator = AppCoordinator(
            container: DependencyContainer.live(modelContext: context)
        )
    }
}
