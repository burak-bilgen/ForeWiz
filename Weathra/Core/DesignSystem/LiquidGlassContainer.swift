import SwiftUI

struct LiquidGlassContainer<Content: View>: View {
    let content: Content
    var useShadow: Bool = true
    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    init(useShadow: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.useShadow = useShadow
    }

    var body: some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(
                cornerRadius: AppTheme.cardRadius,
                style: .continuous
            ))
            .background(
                AppTheme.glassFill(for: colorScheme),
                in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.glassStroke(for: colorScheme), lineWidth: 1)
            }
            .shadow(
                color: AppTheme.glassAccentShadow(for: colorScheme, isEnabled: useShadow),
                radius: useShadow ? 22 : 0,
                y: useShadow ? 12 : 0
            )
            .shadow(
                color: AppTheme.glassDepthShadow(for: colorScheme, isEnabled: useShadow),
                radius: useShadow ? 10 : 0,
                y: useShadow ? 5 : 0
            )
    }
}
