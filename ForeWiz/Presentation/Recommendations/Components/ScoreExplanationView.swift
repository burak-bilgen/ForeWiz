import SwiftUI

struct ScoreExplanationView: View {
    let explanation: String

    var body: some View {
        Text(explanation)
            .font(.body)
            .foregroundStyle(.secondary)
    }
}
