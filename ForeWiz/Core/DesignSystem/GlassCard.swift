import SwiftUI

// MARK: - Liquid Glass Card
/// Premium liquid glass card with animated sheen, depth, and adaptive accent colors.
///
/// Features:
/// - Slow diagonal sheen animation (like Apple Wallet cards)
/// - Deep glass morphism with multi-layer blur
/// - Adaptive accent borders and glows
/// - Micro-interaction press state
/// - Accessibility optimizations with reduceMotion support
struct LiquidGlassCard<Content: View>: View {
    let accentColor: Color
    let isInteractive: Bool
    let innerPadding: CGFloat
    let cornerRadius: CGFloat
    let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var sheenOffset: CGFloat = -1.5

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
                    // 1. Base glass layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)

                    // 2. Animated sheen — smooth diagonal sweep (eases in/out, autoreverses)
                    if !reduceMotion {
                        LiquidCardSheen(
                            cornerRadius: cornerRadius,
                            accentColor: accentColor,
                            offset: sheenOffset
                        )
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 6.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(1.0)
                            ) {
                                sheenOffset = 1.5
                            }
                        }
                    }

                    // 2b. Static shimmer for cards that reduceMotion
                    if reduceMotion {
                        LiquidCardSheen(
                            cornerRadius: cornerRadius,
                            accentColor: accentColor,
                            offset: 0.5
                        )
                    }

                    // 3. Static gradient overlay (adaptive to color scheme)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [
                                        accentColor.opacity(0.0),
                                        accentColor.opacity(0.04),
                                        .white.opacity(0.01),
                                        accentColor.opacity(0.0)
                                    ]
                                    : [
                                        accentColor.opacity(0.0),
                                        accentColor.opacity(0.06),
                                        .white.opacity(0.02),
                                        accentColor.opacity(0.0)
                                    ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // 4. Accent border — refined light-catching stroke (adaptive)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [
                                        accentColor.opacity(0.20),
                                        accentColor.opacity(0.04),
                                        .white.opacity(0.08),
                                        accentColor.opacity(0.02),
                                        .white.opacity(0.04),
                                        accentColor.opacity(0.12)
                                    ]
                                    : [
                                        accentColor.opacity(0.30),
                                        accentColor.opacity(0.06),
                                        .white.opacity(0.15),
                                        accentColor.opacity(0.04),
                                        .white.opacity(0.08),
                                        accentColor.opacity(0.20)
                                    ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )

                    // 5. Bottom edge highlight for depth (softer in dark mode)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(colorScheme == .dark ? .black.opacity(0.30) : .black.opacity(0.18), lineWidth: 1.5)
                        .blur(radius: 0.5)
                        .offset(x: 0, y: 2)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Animated Sheen Layer

private struct LiquidCardSheen: View {
    let cornerRadius: CGFloat
    let accentColor: Color
    let offset: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    .clear,
                    accentColor.opacity(colorScheme == .dark ? 0.06 : 0.10),
                    .white.opacity(colorScheme == .dark ? 0.04 : 0.08),
                    accentColor.opacity(colorScheme == .dark ? 0.03 : 0.05),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 1.6)
            .offset(x: offset * geo.size.width * 0.8)
            .blendMode(.plusLighter)
        }
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
