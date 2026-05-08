import SwiftUI

struct HourlyRecommendationRow: View {
    let recommendation: ActivityRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recommendation.activityType.localizedTitle)
                .font(.headline)
            Text(recommendation.bestWindow.shortDisplayText)
                .font(.body)
            Text(recommendation.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
