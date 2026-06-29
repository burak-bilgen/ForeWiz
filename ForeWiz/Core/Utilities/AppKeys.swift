import Foundation

enum AppKeys {

    enum UserDefaults {
        static let languageOverride = "forewiz.languageOverride.v1"
        static let appTheme = "app_theme"
        static let appAccentColor = "app_accent_color"
        static let wizPathRecentDestinations = "wizpath_recent_destinations"
        static let widgetWeatherData = "com.forewiz.widget.weatherData"
    }

    static let appGroupSuiteName = "group.forewiz"

    enum NotificationName {
        static let appLanguageDidChange = Foundation.Notification.Name("com.forewiz.languageDidChange")
    }
}
