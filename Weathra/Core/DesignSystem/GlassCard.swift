import SwiftUI

/// Standard card wrapper that applies a Liquid Glass surface, comfortable padding,
/// and a flexible width. Use this for the majority of grouped content blocks.
struct GlassCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let tint: Color?

    init(
        cornerRadius: CGFloat = AppTheme.cardRadius,
        padding: CGFloat = AppSpacing.medium,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        LiquidGlassContainer(cornerRadius: cornerRadius, tint: tint) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(padding)
        }
    }
}
