import SwiftUI

@available(iOS 17.0, *)
@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    
    var colorScheme: ColorScheme = .dark
    var accentColor: Color = .blue
    var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    private init() {
        loadSavedTheme()
    }
    
    func toggleDarkMode() {
        colorScheme = isDarkMode ? .light : .dark
        saveTheme()
    }
    
    func setColorScheme(_ scheme: ColorScheme) {
        colorScheme = scheme
        saveTheme()
    }
    
    func setAccentColor(_ color: Color) {
        accentColor = color
        saveTheme()
    }
    
    private func loadSavedTheme() {
        if let saved = UserDefaults.standard.string(forKey: "app_theme") {
            colorScheme = saved == "dark" ? .dark : .light
        }
        
        if let accentData = UserDefaults.standard.data(forKey: "app_accent_color"),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: accentData) {
            accentColor = Color(uiColor: uiColor)
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(isDarkMode ? "dark" : "light", forKey: "app_theme")
        
        let uiColor = UIColor(accentColor)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: "app_accent_color")
        }
    }
}

struct ThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func applyTheme() -> some View {
        modifier(ThemeModifier())
    }
}

struct AdaptiveColor {
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
    
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    static let tertiaryLabel = Color(.tertiaryLabel)
    static let quaternaryLabel = Color(.quaternaryLabel)
    
    static let fill = Color(.systemFill)
    static let secondaryFill = Color(.secondarySystemFill)
    static let tertiaryFill = Color(.tertiarySystemFill)
    
    static let separator = Color(.separator)
    static let opaqueSeparator = Color(.opaqueSeparator)
}

struct AdaptiveCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding()
            .background(AdaptiveColor.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct AdaptiveButtonStyle: ButtonStyle {
    let role: ButtonRole?
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(role == .destructive ? .red : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AdaptiveColor.fill)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == AdaptiveButtonStyle {
    static var adaptive: AdaptiveButtonStyle { AdaptiveButtonStyle(role: nil) }
    static func adaptive(role: ButtonRole?) -> AdaptiveButtonStyle { AdaptiveButtonStyle(role: role) }
}
