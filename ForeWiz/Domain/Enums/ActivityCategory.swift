import Foundation

enum ActivityCategory: String, CaseIterable, Codable, Sendable {
    case fitness
    case leisure
    case social
    case photography
    case outdoors
    
    var localizedTitle: String {
        "activity_category_\(rawValue)"
    }
    
    var iconName: String {
        switch self {
        case .fitness: return "figure.run"
        case .leisure: return "leaf"
        case .social: return "person.3"
        case .photography: return "camera"
        case .outdoors: return "tree"
        }
    }
}
