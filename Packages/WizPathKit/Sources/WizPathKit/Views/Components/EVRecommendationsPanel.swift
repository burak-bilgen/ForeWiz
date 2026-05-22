import SwiftUI

// MARK: - EV Recommendations Panel

public struct EVRecommendationsPanel: View {
    let recommendations: [EVRecommendation]

    public init(recommendations: [EVRecommendation]) {
        self.recommendations = recommendations
    }

    public var body: some View {
        LiquidGlassCard(accentColor: .orange, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "bolt.car.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text(WizPathKitL10n.text("wizpath_ev_title"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "battery.75")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                }

                ForEach(recommendations) { rec in
                    HStack(spacing: 10) {
                        Image(systemName: rec.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(rec.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(rec.description)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}

extension EVRecommendation: Identifiable {
    public var id: String { title }
}
