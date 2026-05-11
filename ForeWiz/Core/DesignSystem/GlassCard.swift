import SwiftUI

struct GlassCard<Content: View>: View {
    var accentColor: Color? = nil
    var innerPadding: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(innerPadding)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}