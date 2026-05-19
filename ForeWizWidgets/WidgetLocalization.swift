import Foundation

/// Lightweight localization helper for the widget target.
/// Reads the language override saved by L10n in the main app via shared UserDefaults.
enum WidgetL10n {
    private static let appGroupSuiteName = "group.forewiz"
    private static let languageOverrideKey = "forewiz.languageOverride.v1"

    /// Returns the current language code ("en" or "tr") from shared UserDefaults,
    /// falling back to the system language if no override is set.
    static var currentLanguageCode: String {
        guard let defaults = UserDefaults(suiteName: appGroupSuiteName),
              let identifier = defaults.string(forKey: languageOverrideKey) else {
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("tr") ? "tr" : "en"
        }
        return identifier.hasPrefix("tr") ? "tr" : "en"
    }

    /// Returns true if the current language is Turkish.
    static var isTurkish: Bool { currentLanguageCode == "tr" }

    /// Returns a localized string for the given key.
    static func text(_ key: String) -> String {
        translations[key]?[currentLanguageCode] ?? key
    }

    // MARK: - Translation Table

    private static let translations: [String: [String: String]] = [
        "widget_outdoor_label": [
            "en": "Outdoor",
            "tr": "Açık Hava"
        ],
        "widget_score_label": [
            "en": "Score",
            "tr": "Puan"
        ],
        "widget_forecast_title": [
            "en": "Forecast",
            "tr": "Tahmin"
        ],
        "widget_today": [
            "en": "Now",
            "tr": "Şimdi"
        ],
        "widget_placeholder_title": [
            "en": "ForeWiz",
            "tr": "ForeWiz"
        ],
        "widget_placeholder_msg": [
            "en": "Open the app to load weather data.",
            "tr": "Hava durumunu görmek için uygulamayı aç."
        ],
        "widget_no_data": [
            "en": "No data",
            "tr": "Veri yok"
        ],
        "widget_name": [
            "en": "ForeWiz",
            "tr": "ForeWiz"
        ],
        "widget_config_name": [
            "en": "Weather Forecast",
            "tr": "Hava Tahmini"
        ],
        "widget_config_desc": [
            "en": "Your daily outdoor score and forecast at a glance.",
            "tr": "Günlük hava puanın ve tahminin bir bakışta."
        ],
        "widget_updated": [
            "en": "Updated",
            "tr": "Güncellendi"
        ],
        "widget_feels_like": [
            "en": "Feels like",
            "tr": "Hissedilen"
        ],
        "widget_humidity": [
            "en": "Humidity",
            "tr": "Nem"
        ],
        "widget_precip": [
            "en": "Precip",
            "tr": "Yağış"
        ],
        "widget_just_now": [
            "en": "Just now",
            "tr": "Az önce"
        ],
        "widget_min_ago": [
            "en": "%d min ago",
            "tr": "%d dk önce"
        ],
        "widget_waiting_title": [
            "en": "Loading…",
            "tr": "Yükleniyor…"
        ],
        "widget_waiting_msg": [
            "en": "Open ForeWiz to load your weather data.",
            "tr": "Hava durumunu yüklemek için uygulamayı aç."
        ],
        "widget_config_error": [
            "en": "Setup needed",
            "tr": "Kurulum gerekli"
        ],
        "widget_config_error_msg": [
            "en": "Reinstall the app to fix widget configuration.",
            "tr": "Widget'ı düzeltmek için uygulamayı yeniden yükle."
        ],
        "widget_corrupted_title": [
            "en": "Update needed",
            "tr": "Güncelleme gerekli"
        ],
        "widget_corrupted_msg": [
            "en": "Open ForeWiz to refresh widget data.",
            "tr": "Widget'ı yenilemek için uygulamayı aç."
        ],
        "widget_stale_title": [
            "en": "Open app to refresh",
            "tr": "Yenilemek için aç"
        ],
        "widget_stale_msg": [
            "en": "Data may be out of date. Open ForeWiz for the latest forecast.",
            "tr": "Veri güncel olmayabilir. Güncel hava durumu için uygulamayı aç."
        ],
        "widget_tap_to_open": [
            "en": "Tap to open",
            "tr": "Açmak İçin Dokun"
        ],
    ]
}
