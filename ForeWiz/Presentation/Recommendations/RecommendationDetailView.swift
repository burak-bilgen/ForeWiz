import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: DailyRecommendation
    @State private var appeared = false

    var body: some View {
        ZStack {
            DetailBackground().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    DetailHeroCard(recommendation: recommendation)
                        .staggerEntrance(index: 0, appeared: appeared)
                    DetailExplanationCard(explanation: recommendation.explanation)
                        .staggerEntrance(index: 1, appeared: appeared)
                    if !recommendation.bestActivityWindows.isEmpty {
                        DetailActivityCard(activities: recommendation.bestActivityWindows)
                            .staggerEntrance(index: 2, appeared: appeared)
                    }
                    DetailOutfitCard(outfit: recommendation.outfit)
                        .staggerEntrance(index: 3, appeared: appeared)
                    if !recommendation.avoidWindows.isEmpty {
                        DetailAvoidCard(avoidWindows: recommendation.avoidWindows)
                            .staggerEntrance(index: 4, appeared: appeared)
                    }
                    if !recommendation.risks.isEmpty {
                        DetailRiskCard(risks: recommendation.risks)
                            .staggerEntrance(index: 5, appeared: appeared)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .refreshable { }
            .safeAreaPadding(.bottom, 12)
        }
        .navigationTitle(L10n.text("recommendation_detail_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { withAnimation { appeared = true } }
    }
}

#Preview {
    NavigationStack {
        RecommendationDetailView(recommendation: .placeholder)
            .preferredColorScheme(.dark)
    }
}
