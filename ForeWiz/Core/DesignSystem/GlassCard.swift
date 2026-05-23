import SwiftUI
import WizPathKit

// MARK: - Legacy GlassCard Wrapper
/// Thin wrapper around WizPathKit's LiquidGlassCard for backward compatibility.
struct GlassCard<Content: View>: View {
    var accentColor: Color? = nil
    var innerPadding: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        LiquidGlassCard(
            accentColor: accentColor ?? Color.liquidAccent,
            innerPadding: innerPadding,
            content: { content }
        )
    }
}

// MARK: - Glass Effect Modifier
struct GlassEffectModifier: ViewModifier {
    let style: UIBlurEffect.Style
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: style))
                    Color.black.opacity(0.10)
                }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
    }
}

private struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

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

// MARK: - Preview
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

            GlassCard {
                Text(L10n.text("preview_legacy_glass"))
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
}

// MARK: - Glass Icon (minimal rounded-square icon)
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
