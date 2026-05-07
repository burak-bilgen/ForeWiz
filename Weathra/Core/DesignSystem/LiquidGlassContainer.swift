import SwiftUI

/// Liquid Glass surface used across the app. On iOS 26+ this leverages the native
/// `.glassEffect` modifier; on older systems it falls back to `.ultraThinMaterial`.
struct LiquidGlassContainer<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let useShadow: Bool
    private let tint: Color?

    @Environment(\.colorScheme) private var colorScheme

    init(
        cornerRadius: CGFloat = AppTheme.cardRadius,
        useShadow: Bool = true,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.useShadow = useShadow
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .modifier(GlassSurfaceModifier(shape: shape, tint: tint))
            .shadow(
                color: useShadow ? .black.opacity(colorScheme == .dark ? 0.30 : 0.06) : .clear,
                radius: useShadow ? 14 : 0,
                y: useShadow ? 8 : 0
            )
    }
}

/// Applies the platform-best glass surface on the supplied shape.
private struct GlassSurfaceModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let tint: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.regular.tint(tint), in: shape)
            } else {
                content.glassEffect(.regular, in: shape)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay { shape.stroke(.white.opacity(0.10), lineWidth: 1) }
        }
    }
}
