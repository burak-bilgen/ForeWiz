import SwiftUI

struct PermissionExplainerView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        LiquidGlassCard {
            HStack(alignment: .top, spacing: 14) {
                GlassIcon(systemName: systemImage, color: .liquidAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(4)
        }
        .accessibilityElement(children: .combine)
    }
}
