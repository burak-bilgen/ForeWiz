import SwiftUI

struct InsightsView: View {
    let recommendation: DailyRecommendation

    var body: some View {
        ZStack {
            InsightsBackground().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    InsightsHeader()
                    InsightsScoreCard(recommendation: recommendation)
                    InsightsActivityCard(recommendation: recommendation)
                    InsightsDayQualityCard(recommendation: recommendation)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .refreshable { }
            .safeAreaPadding(.bottom, 12)
        }
        .navigationTitle(L10n.text("insights_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        InsightsView(recommendation: .placeholder)
    }
}
