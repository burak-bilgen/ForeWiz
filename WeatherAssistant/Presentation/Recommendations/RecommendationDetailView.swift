import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: DailyRecommendation

    var body: some View {
        List {
            Section("Açıklama") {
                Text(recommendation.explanation)
            }
            Section("Aktivite pencereleri") {
                ForEach(recommendation.bestActivityWindows) { activity in
                    HourlyRecommendationRow(recommendation: activity)
                }
            }
        }
        .navigationTitle("Detay")
    }
}
