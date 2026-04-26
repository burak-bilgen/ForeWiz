import SwiftUI

@main
struct WeatherAssistantApp: App {
    @StateObject private var coordinator = AppCoordinator(container: DependencyContainer.live())

    var body: some Scene {
        WindowGroup {
            AppRootView(coordinator: coordinator)
        }
    }
}
