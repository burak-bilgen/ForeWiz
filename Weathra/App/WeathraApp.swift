import SwiftUI

@main
struct WeathraApp: App {
    @StateObject private var coordinator = AppCoordinator(container: DependencyContainer.live())

    var body: some Scene {
        WindowGroup {
            AppRootView(coordinator: coordinator)
        }
    }
}
