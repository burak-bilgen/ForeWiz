import Foundation

enum NotificationCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case morningBriefing
    case outfitSuggestion
    case bestRunWindow
    case avoidHeatWindow
    case rainWarning
    case windWarning
    case uvWarning

    var localizedTitle: String {
        switch self {
        case .morningBriefing:
            "Sabah özeti"
        case .outfitSuggestion:
            "Kıyafet önerisi"
        case .bestRunWindow:
            "En iyi koşu zamanı"
        case .avoidHeatWindow:
            "Sıcaklık planı etkiliyor"
        case .rainWarning:
            "Yağmur saatine dikkat"
        case .windWarning:
            "Rüzgar açık alanı zorlar"
        case .uvWarning:
            "Güneş koruması gerekli"
        }
    }

    var localizedDescription: String {
        switch self {
        case .morningBriefing:
            "Her sabah günün hava özetini ve ne giyeceğini bildirir."
        case .outfitSuggestion:
            "Hava değiştiğinde kıyafet önerisini günceller."
        case .bestRunWindow:
            "Koşu için en uygun saati bildirir."
        case .avoidHeatWindow:
            "Sıcaklık dışarıyı zorlaştıracak seviyeye ulaştığında uyarır."
        case .rainWarning:
            "Yağmur başlamadan kısa süre önce bildirim gönderir."
        case .windWarning:
            "Güçlü rüzgar beklendiğinde uyarır."
        case .uvWarning:
            "UV indeksi yüksek olduğunda güneş koruması hatırlatır."
        }
    }
}
