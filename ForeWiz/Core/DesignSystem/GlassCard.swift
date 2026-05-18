import SwiftUI

// MARK: - Liquid Glass Card
/// Premium liquid glass card with animated sheen, depth, and adaptive accent colors.
///
/// Features:
/// - Animated gradient sheen that flows across the surface
/// - Deep glass morphism with multi-layer blur
/// - Adaptive accent borders and glows
/// - Micro-interaction press state
/// - Accessibility optimizations
struct LiquidGlassCard<Content: View>: View {
    let accentColor: Color
    let isInteractive: Bool
    let innerPadding: CGFloat
    let cornerRadius: CGFloat
    let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    init(
        accentColor: Color = AppTheme.liquidAccent,
        isInteractive: Bool = false,
        innerPadding: CGFloat = 16,
        cornerRadius: CGFloat = 22,
        @ViewBuilder content: () -> Content
    ) {
        self.accentColor = accentColor
        self.isInteractive = isInteractive
        self.innerPadding = innerPadding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(innerPadding)
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)

                    // Static gradient sheen overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.0),
                                    accentColor.opacity(0.08),
                                    .white.opacity(0.04),
                                    accentColor.opacity(0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Subtle inner glow
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.25),
                                    accentColor.opacity(0.08),
                                    .white.opacity(0.12),
                                    accentColor.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )

                    // Inner shadow overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.black.opacity(0.3), lineWidth: 1)
                        .blur(radius: 2)
                        .mask(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .inset(by: -3)
                                .strokeBorder(.black, lineWidth: 4)
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Legacy Support
struct GlassCard<Content: View>: View {
    var accentColor: Color? = nil
    var innerPadding: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        LiquidGlassCard(
            accentColor: accentColor ?? AppTheme.liquidAccent,
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
