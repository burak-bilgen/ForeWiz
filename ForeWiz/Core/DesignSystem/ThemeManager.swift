import SwiftUI
import WizPathKit

/// Manages the visual theme for ForeWiz - always uses Liquid Glass dark aesthetic.
@available(iOS 17.0, *)
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    /// Always dark - liquid glass aesthetic is designed for dark mode.
    let colorScheme: ColorScheme = .dark

    var isDarkMode: Bool { true }

    private init() {}

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

// MARK: - Adaptive Colors

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
