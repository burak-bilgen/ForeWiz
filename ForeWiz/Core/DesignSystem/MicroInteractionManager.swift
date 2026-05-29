import SwiftUI

// MARK: - View Modifiers (inline values, no manager)

struct MicroButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(
                reduceMotion ? .none : (configuration.isPressed
                    ? .spring(response: 0.2, dampingFraction: 0.7)
                    : .spring(response: 0.4, dampingFraction: 0.8)),
                value: configuration.isPressed
            )
    }
}

struct MicroCardEntranceModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .opacity(isVisible ? 1 : 0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.2)
                    : AppTheme.cardSpring.delay(baseDelay + Double(index) * AppTheme.staggerDelay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

struct MicroRefreshModifier: ViewModifier {
    let isRefreshing: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
            .animation(
                reduceMotion
                    ? .none
                    : (isRefreshing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : Animation.default),
                value: isRefreshing
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies premium button micro-interactions.
    func microButton() -> some View {
        buttonStyle(MicroButtonStyle())
    }

    /// Applies card entrance animation with staggered delay.
    func microCardEntrance(index: Int, baseDelay: Double = 0.0) -> some View {
        modifier(MicroCardEntranceModifier(index: index, baseDelay: baseDelay))
    }

    /// Applies refresh rotation animation.
    func microRefresh(isRefreshing: Bool) -> some View {
        modifier(MicroRefreshModifier(isRefreshing: isRefreshing))
    }
}
