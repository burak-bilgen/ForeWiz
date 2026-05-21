import Foundation

// MARK: - App Keys
/// Centralized storage for all UserDefaults keys, notification names, and other string constants.
/// Prevents hardcoded strings scattered across the codebase.
enum AppKeys {
    
    // MARK: - UserDefaults Keys
    
    enum UserDefaults {
        static let languageOverride = "forewiz.languageOverride.v1"
        static let appTheme = "app_theme"
        static let appAccentColor = "app_accent_color"
        static let wizPathRecentDestinations = "wizpath_recent_destinations"
        static let widgetWeatherData = "com.forewiz.widget.weatherData"
    }
    
    // MARK: - App Group
    
    static let appGroupSuiteName = "group.forewiz"
    
    // MARK: - Notification Names
    
    enum NotificationName {
        static let appLanguageDidChange = Foundation.Notification.Name("com.forewiz.languageDidChange")
    }
}
