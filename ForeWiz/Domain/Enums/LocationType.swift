import Foundation

enum LocationType: String, Codable, CaseIterable, Sendable {
    case home
    case work
    case other
    
    var localizedTitle: String {
        "location_\(rawValue)"
    }
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .other: return "mappin"
        }
    }
}
