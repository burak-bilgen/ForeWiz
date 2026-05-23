import SwiftUI

struct InsightsView: View {
    let recommendation: DailyRecommendation
    let onFeedback: () -> Void

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 2) {
                    Button {
                        HapticEngine.shared.light()
                        onFeedback()
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .accessibilityLabel(L10n.text("feedback_sheet_title"))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView(recommendation: .placeholder, onFeedback: {})
    }
}
