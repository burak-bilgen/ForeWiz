import SwiftUI

struct AppRootView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        switch coordinator.rootFlow {
        case .onboarding:
            OnboardingView(
                viewModel: OnboardingViewModel(),
                onCompleted: coordinator.completeOnboarding
            )
        case .main:
            HomeView(
                viewModel: HomeViewModel(
                    recommendation: PreviewWeatherFactory.dailyRecommendation()
                )
            )
        }
    }
}
