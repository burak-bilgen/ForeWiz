import Foundation

enum AppError: Error, Equatable {
    case locationPermissionDenied
    case locationUnavailable
    case weatherUnavailable
    case cacheUnavailable
    case notificationPermissionDenied
    case persistenceFailed
    case unknown

    var userMessage: String {
        switch self {
        case .locationPermissionDenied:
            "Konum izni olmadan bulunduğun yere özel öneri üretemiyoruz."
        case .locationUnavailable:
            "Konum alınamadı. Lütfen daha sonra tekrar dene."
        case .weatherUnavailable:
            "Hava durumu alınamadı. Son kayıtlı öneriyi gösteriyoruz."
        case .cacheUnavailable:
            "Kayıtlı hava önerisi bulunamadı."
        case .notificationPermissionDenied:
            "Bildirim izni kapalı olduğu için akıllı uyarılar gönderilemez."
        case .persistenceFailed:
            "Ayarların kaydedilemedi. Lütfen tekrar dene."
        case .unknown:
            "Beklenmeyen bir hata oluştu."
        }
    }
}
