import SwiftUI

struct AppRootView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var didStart = false

    var body: some View {
        Group {
            switch coordinator.rootFlow {
            case .launching:
                LaunchingView()
            case .onboarding:
                OnboardingView(
                    viewModel: OnboardingViewModel(
                        locationRepository: coordinator.container.locationRepository,
                        notificationRepository: coordinator.container.notificationRepository
                    ),
                    existingProfile: coordinator.profile,
                    onCompleted: coordinator.completeOnboarding
                )
            case .main:
                MainTabView(coordinator: coordinator)
            }
        }
        .preferredColorScheme(coordinator.profile.appearance.colorScheme)
        .tint(AppTheme.accent(for: coordinator.profile.accentPalette))
        .task {
            guard didStart == false else {
                return
            }

            didStart = true
            await coordinator.start()
        }
    }
}

private struct LaunchingView: View {
    var body: some View {
        ZStack {
            AppBackground()
            ProgressView("Hazırlanıyor")
                .font(AppTypography.body)
        }
    }
}

private struct MainTabView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        TabView {
            HomeView(
                viewModel: HomeViewModel(
                    loadHomeRecommendationUseCase: coordinator.container.loadHomeRecommendationUseCase,
                    scheduleSmartNotificationsUseCase: coordinator.container.scheduleSmartNotificationsUseCase,
                    preferencesRepository: coordinator.container.preferencesRepository,
                    dateProvider: coordinator.container.dateProvider
                )
            )
            .tabItem {
                Label("Bugün", systemImage: "sun.max.fill")
            }

            NavigationStack {
                SettingsView(
                    viewModel: SettingsViewModel(
                        profile: coordinator.profile,
                        updateUserPreferencesUseCase: coordinator.container.updateUserPreferencesUseCase,
                        onProfileSaved: coordinator.applyProfile
                    ),
                    resetOnboarding: coordinator.resetToOnboarding
                )
            }
            .tabItem {
                Label("Ayarlar", systemImage: "gearshape.fill")
            }
        }
    }
}

private extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
