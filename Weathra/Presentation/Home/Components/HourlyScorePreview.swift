import SwiftUI

struct HourlyScorePreview: View {
    let scores: [WeatherScore]

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(scores.enumerated()), id: \.offset) { _, score in
                Capsule()
                    .fill(score.rawValue >= 60 ? .green : .orange)
                    .frame(width: 8, height: max(8, CGFloat(score.rawValue)))
            }
        }
        .frame(height: 100)
    }
}
