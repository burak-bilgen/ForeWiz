import SwiftUI
import Combine

struct PulseGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 14
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(pulse ? 0.5 : 0.2), radius: pulse ? radius : radius * 0.6, x: 0, y: 0)
            .onAppear {

                withAnimation(AppTheme.transitionSpring) {
                    pulse = true
                }
            }
    }
}

extension View {
    func pulseGlow(color: Color, radius: CGFloat = 14) -> some View {
        modifier(PulseGlowModifier(color: color, radius: radius))
    }
}

struct PulsingDotsLoader: View {
    var color: Color = .white
    var dotSize: CGFloat = 7
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(phase == i ? 1.0 : 0.28))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(phase == i ? 1.4 : 1.0)
            }
        }
        .onReceive(Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()) { _ in
            phase = (phase + 1) % 3
        }
    }
}
