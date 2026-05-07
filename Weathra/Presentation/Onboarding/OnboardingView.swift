import SwiftUI

/// Three-step onboarding: hero, comparison, setup.
/// Background, controls, and text colours all adapt to light/dark mode automatically.
struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var currentPage = 0
    @State private var showConfetti = false
    @Namespace private var logoNamespace

    var body: some View {
        ZStack {
            AppBackground()

            TabView(selection: $currentPage) {
                HeroPage(logoNamespace: logoNamespace, next: { goTo(1) })
                    .tag(0)
                WhyWeathraPage(logoNamespace: logoNamespace, next: { goTo(2) })
                    .tag(1)
                SetupPage(
                    viewModel: viewModel,
                    isCompleting: isCompleting,
                    complete: complete
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(AppTheme.springSmooth, value: currentPage)

            if showConfetti {
                ConfettiOverlay()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func goTo(_ page: Int) {
        withAnimation(AppTheme.springSmooth) {
            currentPage = page
        }
    }

    private func complete() {
        guard viewModel.canContinue, !isCompleting else { return }

        showConfetti = true
        isCompleting = true
        Task {
            do {
                try await onCompleted(viewModel.makeProfile(inheriting: existingProfile))
            } catch {
                viewModel.setErrorMessage(AppError.persistenceFailed.userMessage)
            }
            isCompleting = false
        }
    }
}
