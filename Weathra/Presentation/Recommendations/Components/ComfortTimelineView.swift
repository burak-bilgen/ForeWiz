import SwiftUI

struct ComfortTimelineView: View {
    let scores: [WeatherScore]

    var body: some View {
        HourlyScorePreview(scores: scores)
            .accessibilityLabel(String(localized: "comfort_timeline_accessibility"))
    }
}
