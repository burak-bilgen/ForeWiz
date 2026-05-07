import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        Self.dictionary[key] ?? key
    }

    private static let dictionary: [String: String] = [
        // MARK: - Home Screen
        "home_title": "Bugun Disarisi",
        "home_daily_summary": "Gunluk Ozet",
        "home_current_location": "Konumum",
        "home_last_saved": "Son guncellenme",
        "home_live": "Canli",
        "home_loading": "Hava durumu yukleniyor...",
        "home_error_retry": "Tekrar Dene",
        "home_updated": "Guncellendi",

        // MARK: - Weather
        "weather_live_forecast": "Anlik Hava",
        "weather_latest_forecast": "Son Veri",
        "weather_feels_like": "Hissedilen",
        "weather_current": "Su An",
        "weather_clear": "Acik",
        "weather_cloudy": "Bulutlu",
        "weather_rain": "Yagisli",
        "weather_snow": "Karli",
        "weather_storm": "Firtinali",
        "weather_foggy": "Sisli",
        "weather_data_provided_by": "Veren:",

        // MARK: - Decisions (Natural Turkish)
        "decision_good": "Harika, disari cik!",
        "decision_moderate": "Idare eder",
        "decision_risky": "Dikkatli ol",
        "decision_avoid": "Disari cikma",

        // MARK: - Widget
        "widget_outdoor_score": "Disari Skoru",
        "widget_best_time": "En Iyi Zaman",

        // MARK: - Forecast
        "forecast_3day": "3 Gunluk",
        "forecast_7day": "7 Gunluk",
        "forecast_14day": "14 Gunluk",
        "forecast_no_best_window": "Belirgin saat yok",
        "forecast_premium_required": "Premium gerekiyor",

        // MARK: - Onboarding (Natural)
        "onboarding_welcome": "Weathra'ya Hos Geldin",
        "onboarding_subtitle": "Hava durumunu bilmekten daha fazlasi.",
        "onboarding_why_weathra": "Neden Weathra?",
        "onboarding_why_subtitle": "Sana ozel hava kararlari.",
        "onboarding_setup_title": "Hizlica Ayarlayalim",
        "onboarding_setup_subtitle": "Deneyiminiakisileştirelim.",
        "onboarding_continue": "Devam",
        "onboarding_ready": "Baslayalim!",
        "onboarding_location_required": "Konum izni lazim",
        "onboarding_feature_decision": "Karar Asistani",
        "onboarding_feature_decision_desc": "Bugun disari cikmali misin? Ne giymelisin?",
        "onboarding_feature_personal": "Kisisel Oneriler",
        "onboarding_feature_personal_desc": "Sana ozel, akilli kararlar.",
        "onboarding_feature_notifications": "Bildirimler",
        "onboarding_feature_notifications_desc": "Firsatlari kacirma.",

        // MARK: - Settings
        "settings_header_title": "Ayarlar",
        "settings_header_subtitle": "Kisisellesitir",
        "settings_appearance_title": "Gorunum",
        "settings_appearance_subtitle": "Tema ve dil",
        "settings_comfort_title": "Konfor",
        "settings_comfort_subtitle": "Tercihlerini belirle",
        "settings_notifications_title": "Bildirimler",
        "settings_notifications_subtitle": "Bildirim ayarlari",
        "settings_permissions_title": "Izinler",
        "settings_permissions_subtitle": "App izinleri",
        "settings_premium_title": "Premium",
        "settings_saved_locations_title": "Konumlarim",
        "settings_saved_locations_subtitle": "Kayitli konumlar",
        "settings_language_title": "Dil",
        "settings_language_subtitle": "Sec",

        // MARK: - Tabs
        "tab_today": "Bugun",
        "tab_settings": "Ayarlar",

        // MARK: - Errors (Natural)
        "error_unknown": "Bir sey oldu. Tekrar dene.",
        "error_location_denied": "Konum erisimi kapali. Ayarlar'a git.",
        "error_location_unavailable": "Konum bulunamadi.",
        "error_weather_unavailable": "Veri alinamiyor.",
        "error_notification_denied": "Bildirimler kapalı.",
        "error_cache_unavailable": "_once veri yok.",

        // MARK: - Premium
        "premium_title": "Weathra Premium",
        "premium_subtitle": "Tum ozellikleri ac.",
        "premium_upgrade": "Premium Al",
        "premium_restore": "Geri Yukle",
        "premium_restore_success": "Basariyla geri yuklendi.",
        "premium_restore_none": "Premium bulunamadi.",

        // MARK: - Activities
        "activity_walking": "Yuruyus",
        "activity_running": "Kosu",
        "activity_cycling": "Bisiklet",
        "activity_outside": "Disari",

        // MARK: - Sensitivity
        "sensitivity_normal": "Normal",
        "sensitivity_hot": "Sicaga hassas",
        "sensitivity_cold": "Soguk hassas",

        // MARK: - Risk
        "risk_low": "Dusuk",
        "risk_medium": "Orta",
        "risk_high": "Yuksek",
        "risk_extreme": "Cok Yuksek",

        // MARK: - About
        "about_legal": "Yasal",
        "about_legal_desc": "Veriler Apple Weather'den.",
        "about_apple_weather_legal": "Apple Weather",
        "about_done": "Tamam",

        // MARK: - Common
        "settings_cancel": "Iptal",
        "settings_save": "Kaydet",

        // MARK: - Notifications
        "notification_morning_briefing": "Sabah Ozeti",
        "notification_morning_briefing_desc": "Her sabah ozet al.",
        "notification_outfit": "Kiyafet",
        "notification_outfit_desc": "Ne giyeyim?",
        "notification_best_run": "Kosu Zamani",
        "notification_best_run_desc": "En uygun kosu saatleri.",
        "notification_uv": "UV Uyarisi",
        "notification_uv_desc": "Gunes korumasi hatirlatmasi.",
        "notification_rain": "Yagmur",
        "notification_rain_desc": "Yagmur oncesi bildirim.",
        "notification_wind": "ruzgar",
        "notification_wind_desc": "Kuvvetli ruzgar uyarisi.",
        "notification_avoid_heat": "Sicaklik",
        "notification_avoid_heat_desc": "Sicaklik uyarisi.",

        // MARK: - Insights
        "insights_score_breakdown": "Skor Detay",
        "insights_temperature": "Sicaklik",
        "insights_precipitation": "Yagis",
        "insights_wind": "Ruzgar",
        "insights_uv_index": "UV",
        "insights_activity_scores": "Aktiviteler",
        "insights_weekly_trend": "Haftalik",
        "insights_comfortable": "Konforlu",
        "insights_uncomfortable": "Konforsuz",
        "insights_low_risk": "Risk Dusuk",
        "insights_calm": "Sakin",
        "insights_moderate": "Orta",
        "insights_trend_description": "Bu hafta stabil.",

        // MARK: - Avoid Hours
        "avoid_hours_title": "Kacinlacak Saatler",
        "avoid_hours_none": "Kacinlacak yok",

        // MARK: - Appearance
        "appearance_light": "Acik",
        "appearance_dark": "Koyu",
        "appearance_system": "Otomatik",

        // MARK: - Language
        "language_turkish": "Turkce",
        "language_english": "Ingilizce",
        "language_system": "Sistem",

        // MARK: - Location Picker
        "location_picker_add_title": "Yeni Konum",
        "location_picker_add_button": "Ekle",
        "location_picker_name_section": "Isim",
        "location_picker_name_placeholder": "Ev, Is...",
        "location_picker_coordinates": "Koordinatlar",
        "location_picker_latitude": "Enlem",
        "location_picker_longitude": "Boylam",
        "location_picker_default_coords_note": "Haritadan sec",
        "location_picker_cancel": "Iptal",
        "location_picker_close": "Kapat",
        "location_picker_edit": "Duzenle",
        "location_picker_done": "Tamam",
        "location_picker_empty": "Konum yok",
        "location_picker_empty_hint": "Yeni eklemek icin +",

        // MARK: - Widget Best Time
        "widget_best_time": "En Iyi Zaman",
        "today_label": "BUGUN",
        "premium_feature_hourly": "Saatlik",

        // Premium New
        "premium_feature_forecast_14day": "14 Gunluk",
        "premium_feature_forecast_14day_desc": "Iki hafta oneri.",
        "premium_feature_alerts": "Uyarilar",
        "premium_feature_alerts_desc": "Firtina, sel uyarilari.",
        "premium_feature_watch": "Watch",
        "premium_feature_watch_desc": "Bileginden kontrol.",

        "risk_heat": "Sicak",
        "risk_uv": "UV",
        "risk_rain": "Yagmur",
        "risk_wind": "Ruzgar",
        "risk_humidity": "Nem",
        "risk_cold": "Soguk",
        "risk_storm": "Firtina",
    ]
}