import SwiftUI

struct GlassCard<Content: View>: View {
    var accentColor: Color? = nil
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        accentColor != nil
                            ? accentColor!.opacity(0.15)
                            : .white.opacity(0.08),
                        lineWidth: 1
                    )
            )
    }
}
