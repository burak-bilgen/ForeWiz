import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        LiquidGlassContainer {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.large)
        }
    }
}
