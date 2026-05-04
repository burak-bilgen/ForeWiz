import Foundation

enum AppError: Error, Equatable {
    case locationPermissionDenied
    case locationUnavailable
    case weatherUnavailable
    case weatherKitPermissionMissing
    case weatherKitFailed(String)
    case cacheUnavailable
    case notificationPermissionDenied
    case persistenceFailed
    case unknown

    var userMessage: String {
        switch self {
        case .locationPermissionDenied:
            "Konum izni verilmedi. Ayarlar'dan Weathra'ya konum erişimi açarsan bulunduğun yere özel öneriler sunabiliriz."
        case .locationUnavailable:
            "Konumun şu an alınamıyor. İnternet bağlantını kontrol edip tekrar dene."
        case .weatherUnavailable:
            "Hava durumu verisi şu an alınamıyor. En son kaydedilen öneriyi gösteriyoruz."
        case .weatherKitPermissionMissing:
            "WeatherKit kimlik doğrulaması reddedildi. Apple Developer'da bu Bundle ID için WeatherKit'i hem App Services hem App Capabilities altında açıp provisioning profilini yenile."
        case .weatherKitFailed(let reason):
            "WeatherKit yanıt vermedi: \(reason)"
        case .cacheUnavailable:
            "Henüz kayıtlı bir hava önerisi yok. İlk veriyi almak için internet bağlantısı gerekiyor."
        case .notificationPermissionDenied:
            "Bildirim izni kapalı. Ayarlar'dan açarsan hava değişimlerinde seni uyarabiliriz."
        case .persistenceFailed:
            "Bir sorun oluştu ve ayarların kaydedilemedi. Lütfen tekrar dene."
        case .unknown:
            "Beklenmeyen bir hata oluştu. Uygulamayı kapatıp yeniden açmayı dene."
        }
    }
}
