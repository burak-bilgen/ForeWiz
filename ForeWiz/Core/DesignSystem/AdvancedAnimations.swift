import SwiftUI

/// Lightweight animated gradient background - transitions between colors smoothly.
struct AnimatedGradientBackground: View {
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)

    let colors: [Color]
    let animationDuration: Double

    init(colors: [Color] = [.blue, .purple, .pink], animationDuration: Double = 8) {
        self.colors = colors
        self.animationDuration = animationDuration
    }

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: start,
            endPoint: end
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                start = UnitPoint(x: 1, y: 1)
                end = UnitPoint(x: 0, y: 0)
            }
        }
    }
}

/// Neon glow effect - layered shadows around content.
struct NeonGlowEffect: ViewModifier {
    let color: Color
    let intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: intensity, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: intensity * 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: intensity * 3, x: 0, y: 0)
    }
}

extension View {
    func neonGlow(color: Color = .cyan, intensity: CGFloat = 10) -> some View {
        modifier(NeonGlowEffect(color: color, intensity: intensity))
    }
}
