import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var currentPage = 0
    @State private var showConfetti = false
    @Namespace private var logoNamespace
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                TabView(selection: $currentPage) {
                    HeroPage(
                        logoNamespace: logoNamespace,
                        next: { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 1 } }
                    )
                    .tag(0)

                    WhyWeathraPage(
                        logoNamespace: logoNamespace,
                        next: { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 2 } }
                    )
                    .tag(1)

                    SetupPage(
                        viewModel: viewModel,
                        isCompleting: isCompleting,
                        complete: complete
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                if showConfetti {
                    ConfettiOverlay()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .navigationTitle(L10n.text("onboarding_welcome"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func complete() {
        guard viewModel.canContinue, !isCompleting else {
            return
        }

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

// MARK: - Page 1: Hero / Value Proposition
