import SwiftUI
import WizPathKit

extension View {
    func glassEffect(
        in shape: some Shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
    ) -> some View {
        self.background(
            shape
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    shape
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .clipShape(shape)
    }
}

struct GlassIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.12))
                .frame(width: 36, height: 36)
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            LiquidGlassCard(accentColor: .green) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text(L10n.text("preview_liquid_glass"))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Text(L10n.text("preview_liquid_glass_desc"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            LiquidGlassCard(accentColor: .liquidAccent) {
                Text(L10n.text("preview_legacy_glass"))
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
}
