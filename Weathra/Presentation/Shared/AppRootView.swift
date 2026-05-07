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
            ProgressView(L10n.text( "launch_preparing"))
                .font(AppTypography.body)
        }
    }
}

private struct MainTabView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var showInsightsPaywall = false

    var body: some View {
        TabView {
            HomeView(
                viewModel: HomeViewModel(
                    loadHomeRecommendationUseCase: coordinator.container.loadHomeRecommendationUseCase,
                    scheduleSmartNotificationsUseCase: coordinator.container.scheduleSmartNotificationsUseCase,
                    preferencesRepository: coordinator.container.preferencesRepository,
                    widgetRepository: coordinator.container.widgetRepository,
                    dateProvider: coordinator.container.dateProvider,
                    selectedLocationName: coordinator.profile.savedLocations.first(where: { $0.id == coordinator.profile.selectedLocationID })?.name ?? L10n.text( "home_current_location")
                ),
                savedLocations: $coordinator.profile.savedLocations,
                selectedLocationID: $coordinator.profile.selectedLocationID,
                isPremium: coordinator.container.subscriptionManager.isPremium,
                store: coordinator.container.subscriptionManager,
                onRecommendationLoaded: { recommendation in
                    coordinator.updateRecommendation(recommendation)
                }
            )
            .tabItem {
                Label(L10n.text( "tab_today"), systemImage: "sun.max.fill")
            }

            NavigationStack {
                InsightsView(
                    recommendation: coordinator.latestRecommendation ?? DailyRecommendation(
                        generatedAt: Date(),
                        outdoorDecision: .good,
                        outdoorScore: WeatherScore(rawValue: 0),
                        bestOutdoorWindow: nil,
                        bestActivityWindows: [],
                        avoidWindows: [],
                        outfit: OutfitRecommendation(title: "", items: [], accessories: [], warning: nil),
                        risks: [],
                        summaryText: "",
                        explanation: ""
                    ),
                    isPremium: coordinator.container.subscriptionManager.isPremium,
                    showPaywall: $showInsightsPaywall
                )
                .sheet(isPresented: $showInsightsPaywall) {
                    PaywallView(store: coordinator.container.subscriptionManager)
                }
            }
            .tabItem {
                Label(L10n.text( "premium_feature_analytics"), systemImage: "chart.bar")
            }

            NavigationStack {
                SettingsView(
                    viewModel: SettingsViewModel(
                        profile: coordinator.profile,
                        updateUserPreferencesUseCase: coordinator.container.updateUserPreferencesUseCase,
                        subscriptionManager: coordinator.container.subscriptionManager,
                        onProfileSaved: coordinator.applyProfile,
                        onResetOnboarding: coordinator.resetToOnboarding
                    )
                )
            }
            .tabItem {
                Label(L10n.text( "tab_settings"), systemImage: "gearshape.fill")
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
