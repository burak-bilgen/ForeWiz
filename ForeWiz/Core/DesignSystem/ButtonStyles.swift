import SwiftUI

// MARK: - Button Styles

struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(AppTheme.pressSpring, value: configuration.isPressed)
    }
}

struct FullTapAreaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.78 : 1.0)
            .animation(AppTheme.pressSpring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == FullTapAreaButtonStyle {
    static var fullTapArea: FullTapAreaButtonStyle { FullTapAreaButtonStyle() }
}

extension View {
    func pressScale(_ scale: CGFloat = 0.96) -> some View {
        buttonStyle(PressScaleButtonStyle(scale: scale))
    }
}
