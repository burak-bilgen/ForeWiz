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
                        notificationRepository: coordinator.container.notificationRepository,
                        profile: coordinator.profile
                    ),
                    existingProfile: coordinator.profile,
                    onCompleted: coordinator.completeOnboarding
                )
            case .main:
                MainTabView(coordinator: coordinator)
            }
        }
        .preferredColorScheme(coordinator.profile.appearance.colorScheme)
        .environment(\.locale, coordinator.profile.language.locale)
        .tint(AppTheme.accent)
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
            ProgressView("Weathra hazırlanıyor…")
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
                        onProfileSaved: coordinator.applyProfile,
                        onResetOnboarding: coordinator.resetToOnboarding
                    )
                )
            }
            .tabItem {
                Label("Ayarlar", systemImage: "gearshape.fill")
            }
        }
    }
}

private extension AppLanguage {
    var locale: Locale {
        if let localeIdentifier {
            Locale(identifier: localeIdentifier)
        } else {
            .autoupdatingCurrent
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
