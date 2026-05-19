import SwiftUI

// MARK: - Compact Footer

struct CompactFooter: View {
    let attribution: WeatherAttributionInfo
    let lastUpdatedText: String

    var body: some View {
        VStack(spacing: 6) {
            // Attribution / Legal text
            Group {
                if let legal = attribution.legalAttributionText, !legal.isEmpty {
                    Text(legal)
                } else {
                    Text(L10n.formatted("home_attribution_powered", attribution.serviceName))
                }
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.25))
            .multilineTextAlignment(.center)

            if !lastUpdatedText.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 9))
                    Text(L10n.formatted("home_attribution_updated", lastUpdatedText))
                }
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.15))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 0.5)
        )
    }
}
