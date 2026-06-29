import Foundation
import OSLog
import SwiftData

@MainActor
final class ContainerProvider {
    static let shared = ContainerProvider()

    private var _container: DependencyContainer?

    var container: DependencyContainer {
        get async throws {
            if let container = _container {
                return container
            }

            let modelContainer: ModelContainer
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: false)
                modelContainer = try ModelContainer(
                    for: UserPreferencesModel.self,
                    WeatherSnapshotModel.self,
                    configurations: config
                )
            } catch {
                AppLogger.persistence.error("Persistent container failed: \(error.localizedDescription)")
                do {
                    let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                    modelContainer = try ModelContainer(
                        for: UserPreferencesModel.self,
                        WeatherSnapshotModel.self,
                        configurations: fallbackConfig
                    )
                } catch {
                    AppLogger.persistence.error("Fallback container also failed: \(error.localizedDescription)")
                    throw error
                }
            }

            let context = ModelContext(modelContainer)
            let newContainer = DependencyContainer.live(modelContext: context)
            _container = newContainer
            return newContainer
        }
    }

    private init() {}
}
