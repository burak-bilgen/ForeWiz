import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        Self.dictionary[key] ?? key
    }

    private static let dictionary: [String: String] = [
        // MARK: - Home
        "home_title": "Bugün Dışarısı Nasıl?",
        "home_daily_summary": "Sana Özel Günlük Özet",
        "home_current_location": "Bulunduğum Konum",
        "home_last_saved": "Son Kayıt",
        "home_live": "Canlı",
        "home_loading": "Hava durumun yükleniyor...",
        "home_error_retry": "Yeniden Dene",
        "home_updated": "Güncellendi",

        // MARK: - Weather
        "weather_live_forecast": "Anlık Hava",
        "weather_latest_forecast": "Son Veri",
        "weather_feels_like": "Hissedilen",
        "weather_current": "Şu An",
        "weather_clear": "Açık",
        "weather_cloudy": "Bulutlu",
        "weather_rain": "Yağışlı",
        "weather_snow": "Karlı",
        "weather_storm": "Fırtınalı",
        "weather_foggy": "Sisli",
        "weather_data_provided_by": "Veren:",

        // MARK: - Decision
        "decision_good": "Güzel Bir Gün, Dışarı Çık!",
        "decision_moderate": "İdare Eder, Dikkatli Ol",
        "decision_risky": "Dikkat - Riskli Saatler Var",
        "decision_avoid": "Bugün Dışarı Çıkma",

        // MARK: - Widget
        "widget_outdoor_score": "Dışarı Skoru",
        "widget_best_time": "En İyi Zaman",

        // MARK: - Forecast
        "forecast_3day": "3 Günlük Tahmin",
        "forecast_7day": "7 Günlük Tahmin",
        "forecast_no_best_window": "Belirgin Saat Yok",
        "forecast_premium_required": "Premium Gerekli",

        // MARK: - Onboarding
        "onboarding_welcome": "Weathra'ya Hoş Geldin",
        "onboarding_subtitle": "Hava durumunu kontrol etmekten daha fazlası.",
        "onboarding_why_weathra": "Neden Weathra?",
        "onboarding_why_subtitle": "Sıradan hava durumu uygulamaları ile biz farkımızı gösteriyoruz.",
        "onboarding_setup_title": "Hızlıca Ayarlayalım",
        "onboarding_setup_subtitle": "Sana özel bir deneyim için birkaç tercih belirleyelim.",
        "onboarding_continue": "Devam Et",
        "onboarding_ready": "Hazırım, Başlayalım!",
        "onboarding_location_required": "Devam etmek için konum izni gerekli",
        "onboarding_feature_decision": "Karar Asistanı",
        "onboarding_feature_decision_desc": "Bugün dışarı çıkmalı mısın? Ne giymelisin? Hangi saat en rahat? Tek bakışta gör.",
        "onboarding_feature_personal": "Kişisel Öneriler",
        "onboarding_feature_personal_desc": "Sıcağa mı hassassan? Koşmayı mı seversin? Öneriler sana özel.",
        "onboarding_feature_notifications": "Akıllı Bildirimler",
        "onboarding_feature_notifications_desc": "Yağmur başlamadan, UV yükselmeden, koşu için en iyi saatte uyar.",

        // MARK: - Settings
        "settings_header_title": "Ayarlar",
        "settings_header_subtitle": "Kişiselleştir ve Yönet",
        "settings_appearance_title": "Görünüm",
        "settings_appearance_subtitle": "Tema ve Dil",
        "settings_comfort_title": "Konfor Tercihleri",
        "settings_comfort_subtitle": "Birimler ve Hassasiyet",
        "settings_notifications_title": "Bildirimler",
        "settings_notifications_subtitle": "Akıllı Bildirim Ayarları",
        "settings_permissions_title": "İzinler",
        "settings_permissions_subtitle": "Uygulama İzinleri",
        "settings_premium_title": "Premium",
        "settings_saved_locations_title": "Kayıtlı Konumlar",
        "settings_saved_locations_subtitle": "Kayıtlı konumlarını yönet",
        "settings_language_title": "Dil",
        "settings_language_subtitle": "Uygulama dilini değiştir",

        // MARK: - Tabs
        "tab_today": "Bugün",
        "tab_settings": "Ayarlar",

        // MARK: - Errors
        "error_unknown": "Beklenmeyen bir hata oluştu.",
        "error_location_denied": "Konum izni verilmedi. Ayarlar'dan açabilirsin.",
        "error_location_unavailable": "Konum şu an alınamıyor.",
        "error_weather_unavailable": "Hava durumu verisi şu an alınamıyor.",
        "error_notification_denied": "Bildirim izni kapalı. Ayarlar'dan açabilirsin.",
        "error_cache_unavailable": "Henüz kayıtlı bir hava önerisi yok.",

        // MARK: - Premium
        "premium_title": "Weathra Premium",
        "premium_subtitle": "Hava kararlarını bir üst seviyeye taşı.",
        "premium_upgrade": "Premium'a Geç",
        "premium_restore": "Satın Alımları Geri Yükle",
        "premium_restore_success": "Premium üyeliğin başarıyla geri yüklendi.",
        "premium_restore_none": "Aktif Premium üyelik bulunamadı.",

        // MARK: - Activities
        "activity_walking": "Yürüyüş",
        "activity_running": "Koşu",
        "activity_cycling": "Bisiklet",
        "activity_outside": "Dışarı",

        // MARK: - Sensitivity
        "sensitivity_normal": "Normal",
        "sensitivity_hot": "Çabuk Bunarım",
        "sensitivity_cold": "Çabuk Üşürüm",

        // MARK: - Risk
        "risk_low": "Düşük",
        "risk_medium": "Orta",
        "risk_high": "Yüksek",
        "risk_extreme": "Çok Yüksek",

        // MARK: - About
        "about_legal": "Yasal Bilgi",
        "about_legal_desc": "Tahminler Apple Weather tarafından sağlanır.",
        "about_apple_weather_legal": "Apple Weather Yasal Sayfası",
        "about_done": "Bitti",

        // MARK: - Common
        "settings_cancel": "İptal",
        "settings_save": "Kaydet",

        // MARK: - Notification Titles
        "notification_morning_briefing": "Sabah Özeti",
        "notification_morning_briefing_desc": "Her sabah günün hava özetini gönderir.",
        "notification_outfit": "Kıyafet Önerisi",
        "notification_outfit_desc": "Hava değiştiğinde kıyafet önerisini günceller.",
        "notification_best_run": "En İyi Koşu Zamanı",
        "notification_best_run_desc": "Koşu için en uygun saati bildirir.",
        "notification_uv": "Güneşe Dikkat",
        "notification_uv_desc": "UV indeksi yüksek olduğunda güneş koruması hatırlatır.",
        "notification_rain": "Yağmur Yaklaşıyor",
        "notification_rain_desc": "Yağmur başlamadan kısa süre önce bildirim gönderir.",
        "notification_wind": "Rüzgara Dikkat",
        "notification_wind_desc": "Kuvvetli rüzgar beklendiğinde uyar��r.",
        "notification_avoid_heat": "Sıcaklık Uyarısı",
        "notification_avoid_heat_desc": "Sıcaklık dışarıda kalmayı zorlaştıracak seviyeye ulaştığında uyarır.",

        // MARK: - Insights
        "insights_score_breakdown": "Skor Detayı",
        "insights_temperature": "Sıcaklık",
        "insights_precipitation": "Yağış",
        "insights_wind": "Rüzgar",
        "insights_uv_index": "UV İndeksi",
        "insights_activity_scores": "Aktivite Skorları",
        "insights_weekly_trend": "Haftalık Trend",
        "insights_comfortable": "Konforlu",
        "insights_uncomfortable": "Konforsuz",
        "insights_low_risk": "Düşük Risk",
        "insights_calm": "Sakin",
        "insights_moderate": "Orta",
        "insights_trend_description": "Bu hafta hava koşulları genel olarak stabil.",

        // MARK: - Avoid Hours
        "avoid_hours_title": "Kaçınılacak Saatler",
        "avoid_hours_none": "Önerilen kaçınılacak saat yok",

        // MARK: - Appearance
        "appearance_light": "Açık",
        "appearance_dark": "Koyu",
        "appearance_system": "Sistem",

        // MARK: - Language
        "language_turkish": "Türkçe",
        "language_english": "English",
        "language_system": "Sistem",

        // MARK: - Location Picker
        "location_picker_add_title": "Yeni Konum",
        "location_picker_add_button": "Ekle",
        "location_picker_name_section": "Konum Adı",
        "location_picker_name_placeholder": "Ev, İş, Yazlık...",
        "location_picker_coordinates": "Koordinatlar",
        "location_picker_latitude": "Enlem",
        "location_picker_longitude": "Boylam",
        "location_picker_default_coords_note": "Harita üzerinden seçebilirsin",
        "location_picker_cancel": "İptal",
        "location_picker_close": "Kapat",
        "location_picker_edit": "Düzenle",
        "location_picker_done": "Bitti",
        "location_picker_empty": "Kayıtlı konum yok",
        "location_picker_empty_hint": "Yeni bir konum eklemek için (+) butonuna tıkla",

        // MARK: - Ad
        "ad_label_text": "Reklam",
        "ad_space_text": "Reklam alanı",

        // MARK: - Comfort Timeline
        "comfort_timeline_accessibility": "Saatlik konfor zaman çizelgesi",

        // MARK: - Onboarding Extended
        "onboarding_comfort_title": "Konfor Tercihlerin",
        "onboarding_comfort_subtitle": "Hava koşullarına nasıl tepki verirsin?",
        "onboarding_activities": "Aktiviteler",
        "onboarding_comparison_what_todo": "Dışarı çıkay mı?",
        "onboarding_comparison_what_todo_other": "Hava durumuna bakayım, kendim karar vereyim",
        "onboarding_comparison_what_todo_weathra": "Weathra bana net bir öneri versin",
        "onboarding_comparison_what_wear": "Ne giysem?",
        "onboarding_comparison_what_wear_other": "Termose bakayım, deneyimlerime göre karar verelim",
        "onboarding_comparison_what_wear_weathra": "Weathra tam kıyafet önersin",
        "onboarding_comparison_best_time": "En iyi zaman?",
        "onboarding_comparison_best_time_other": "Saat saat kontrol edeyim",
        "onboarding_comparison_best_time_weathra": "Weathra en ideal zamanı söylesin",

        // MARK: - WeatherKit Errors
        "error_weatherkit_auth": "WeatherKit yetkilendirme başarısız.",
        "error_weatherkit_failed": "WeatherKit yanıt vermedi:",
        "error_weatherkit_unknown": "Bilinmeyen WeatherKit hatası.",

        // MARK: - Risk Types
        "risk_heat": "Sıcaklık",
        "risk_uv": "UV",
        "risk_rain": "Yağmur",
        "risk_wind": "Rüzgar",
        "risk_humidity": "Nem",
        "risk_cold": "Soğuk",
        "risk_storm": "Fırtına",
    ]
}