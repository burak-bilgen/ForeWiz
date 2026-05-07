import SwiftUI

struct ComfortTimelineView: View {
    let scores: [WeatherScore]

    var body: some View {
        HourlyScorePreview(scores: scores)
            .accessibilityLabel(L10n.text("comfort_timeline_accessibility"))
    }
}
