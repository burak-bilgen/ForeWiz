import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                content
                    .padding(AppSpacing.large)
            }
            .navigationTitle("Bugün")
            .task {
                viewModel.onAppear()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Öneri hazırlanıyor")
        case .failed(let message):
            ScreenErrorView(message: message, retryTitle: "Tekrar dene", retry: viewModel.onAppear)
        case .loaded(let state):
            ScrollView {
                VStack(spacing: AppSpacing.medium) {
                    DailyDecisionCard(recommendation: state.recommendation)
                    OutfitCard(outfit: state.recommendation.outfit)
                    WeatherRiskSection(risks: state.recommendation.risks)
                    Text(state.lastUpdatedText)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
