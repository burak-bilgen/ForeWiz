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
            "Sıcak saat uyarısı"
        case .rainWarning:
            "Yağmur uyarısı"
        case .windWarning:
            "Rüzgar uyarısı"
        case .uvWarning:
            "UV uyarısı"
        }
    }
}
