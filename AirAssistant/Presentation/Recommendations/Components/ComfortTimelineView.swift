import SwiftUI

struct ComfortTimelineView: View {
    let scores: [WeatherScore]

    var body: some View {
        HourlyScorePreview(scores: scores)
            .accessibilityLabel("Saatlik konfor zaman çizelgesi")
    }
}
