import SwiftUI

@main
struct HavaAsistaniApp: App {
    @StateObject private var coordinator = AppCoordinator(container: DependencyContainer.live())

    var body: some Scene {
        WindowGroup {
            AppRootView(coordinator: coordinator)
        }
    }
}
