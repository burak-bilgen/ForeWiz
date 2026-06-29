import SwiftUI
import WizPathKit

@available(iOS 17.0, *)
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    let colorScheme: ColorScheme = .dark

    var isDarkMode: Bool { true }

    private init() {}

    var accentColor: Color { AppTheme.liquidAccent }
    var accentSoft: Color { AppTheme.liquidAccentSoft }
    var success: Color { AppTheme.success }
    var warning: Color { AppTheme.warning }
    var danger: Color { AppTheme.danger }

    var cardGradient: LinearGradient {
        AppTheme.ambientGradient(for: .dark)
    }
}

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
