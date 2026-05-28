import SwiftUI

// MARK: - Compact Footer

struct CompactFooter: View {
    let attribution: WeatherAttributionInfo
    let lastUpdatedText: String

    var body: some View {
        VStack(spacing: 8) {
            // Apple Weather Attribution Link
            Link(destination: URL(string: attribution.legalPageURLString ?? "https://weatherkit.apple.com/legal-attribution.html")!) {
                HStack(spacing: 4) {
                    Text(L10n.text("apple_weather_trademark"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.40))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.04), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
            }

            // Legal text if present
            if let legal = attribution.legalAttributionText, !legal.isEmpty {
                Text(legal)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.20))
                    .multilineTextAlignment(.center)
            }

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
