import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                content
            }
            .navigationBarTitleDisplayMode(.inline)
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
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HomeHeaderView(lastUpdatedText: state.lastUpdatedText)
                    DailyDecisionCard(recommendation: state.recommendation)
                    QuickInsightGrid(recommendation: state.recommendation)
                    ActivityWindowsSection(recommendations: state.recommendation.bestActivityWindows)
                    OutfitCard(outfit: state.recommendation.outfit)
                    AvoidHoursCard(avoidWindows: state.recommendation.avoidWindows)
                    WeatherRiskSection(risks: state.recommendation.risks)
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.top, AppSpacing.medium)
                .padding(.bottom, AppSpacing.xLarge)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct HomeHeaderView: View {
    let lastUpdatedText: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text("WeatherAssistant")
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
                .minimumScaleFactor(0.85)
                .lineLimit(1)

            HStack(spacing: AppSpacing.small) {
                Label("Bugünün özeti", systemImage: "sparkles")
                Text(lastUpdatedText)
            }
            .font(AppTypography.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        .padding(.horizontal, AppSpacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}
