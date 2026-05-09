import SwiftUI

struct AppRootView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var deepLinkHandler: DeepLinkHandler
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
        .tint(.blue)
        .task {
            guard didStart == false else {
                return
            }

            didStart = true
            await coordinator.start()
        }
        .onChange(of: deepLinkHandler.pendingLink) { _, newLink in
            handleDeepLink(newLink)
        }
    }

    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }

        switch link {
        case .settings:
            coordinator.showSettings = true
        case .insights:
            coordinator.selectedTab = 1
        case .paywall:
            coordinator.showPaywall = true
        case .onboarding:
            coordinator.rootFlow = .onboarding
        case .home:
            coordinator.selectedTab = 0
        case .recommendationDetail:
            break
        }

        deepLinkHandler.clear()
    }
}

private struct LaunchingView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 56, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, isActive: animate)

                Text(L10n.text("launch_preparing"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { animate = true }
    }
}

private struct MainTabView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var subscriptionManager: StoreKitSubscriptionManager
    @StateObject private var homeViewModel: HomeViewModel
    @State private var showInsightsPaywall = false

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        self.subscriptionManager = coordinator.container.subscriptionManager
        let name = coordinator.profile.savedLocations
            .first { $0.id == coordinator.profile.selectedLocationID }?
            .name ?? L10n.text("home_current_location")
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            loadHomeRecommendationUseCase: coordinator.container.loadHomeRecommendationUseCase,
            scheduleSmartNotificationsUseCase: coordinator.container.scheduleSmartNotificationsUseCase,
            preferencesRepository: coordinator.container.preferencesRepository,
            widgetRepository: coordinator.container.widgetRepository,
            dateProvider: coordinator.container.dateProvider,
            selectedLocationName: name
        ))
    }

    var body: some View {
        tabContent
    }

    @ViewBuilder
    private var tabContent: some View {
        TabView {
            HomeView(
                viewModel: homeViewModel,
                savedLocations: $coordinator.profile.savedLocations,
                selectedLocationID: $coordinator.profile.selectedLocationID,
                isPremium: subscriptionManager.isPremium,
                store: subscriptionManager,
                onRecommendationLoaded: { recommendation in
                    coordinator.updateRecommendation(recommendation)
                }
            )
            .tabItem {
                Label(L10n.text("tab_today"), systemImage: "sun.max.fill")
            }

            NavigationStack {
                if let recommendation = coordinator.latestRecommendation {
                    InsightsView(
                        recommendation: recommendation,
                        isPremium: subscriptionManager.isPremium,
                        showPaywall: $showInsightsPaywall
                    )
                    .sheet(isPresented: $showInsightsPaywall) {
                        PaywallView(store: subscriptionManager)
                    }
                } else {
                    InsightsPlaceholderView()
                }
            }
            .tabItem {
                Label(L10n.text("premium_feature_analytics"), systemImage: "chart.bar")
            }

            NavigationStack {
                SettingsView(
                    viewModel: SettingsViewModel(
                        profile: coordinator.profile,
                        updateUserPreferencesUseCase: coordinator.container.updateUserPreferencesUseCase,
                        subscriptionManager: subscriptionManager,
                        onProfileSaved: coordinator.applyProfile,
                        onResetOnboarding: coordinator.resetToOnboarding
                    )
                )
            }
            .tabItem {
                Label(L10n.text("tab_settings"), systemImage: "gearshape.fill")
            }
        }
    }

}

private struct InsightsPlaceholderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.06, green: 0.12, blue: 0.26)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 48))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.5))
                Text(L10n.text("home_loading"))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
        .navigationTitle(L10n.text("premium_feature_analytics"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
