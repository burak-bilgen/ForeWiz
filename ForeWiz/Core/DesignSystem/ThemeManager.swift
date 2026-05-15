import SwiftUI

/// Manages the visual theme for ForeWiz - always uses Liquid Glass dark aesthetic.
@available(iOS 17.0, *)
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    /// Always dark - liquid glass aesthetic is designed for dark mode.
    let colorScheme: ColorScheme = .dark

    var isDarkMode: Bool { true }

    private init() {}

    // Theme is locked to dark mode for the liquid glass experience.
    func toggleDarkMode() {}
    func setColorScheme(_: ColorScheme) {}

    // MARK: - Convenience Accessors

    var accentColor: Color { AppTheme.liquidAccent }
    var accentSoft: Color { AppTheme.liquidAccentSoft }
    var success: Color { AppTheme.success }
    var warning: Color { AppTheme.warning }
    var danger: Color { AppTheme.danger }

    var cardGradient: LinearGradient {
        AppTheme.ambientGradient(for: .dark)
    }
}

// MARK: - Theme Modifier

struct ThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
    }
}

extension View {
    func applyTheme() -> some View {
        modifier(ThemeModifier())
    }
}

// MARK: - Legacy Support

struct AdaptiveColor {
    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)
    static let tertiaryLabel = Color(uiColor: .tertiaryLabel)
    static let fill = Color(uiColor: .systemFill)
    static let separator = Color(uiColor: .separator)
}

struct AdaptiveCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        LiquidGlassCard {
            content
        }
    }
}

struct AdaptiveButtonStyle: ButtonStyle {
    let role: ButtonRole?
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(role == .destructive ? AppTheme.coral : .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AdaptiveButtonStyle {
    static var adaptive: AdaptiveButtonStyle { AdaptiveButtonStyle(role: nil) }
    static func adaptive(role: ButtonRole?) -> AdaptiveButtonStyle { AdaptiveButtonStyle(role: role) }
}
