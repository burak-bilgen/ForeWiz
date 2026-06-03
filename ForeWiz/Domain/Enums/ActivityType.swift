import Foundation

enum ActivityType: String, Codable, Hashable, Sendable, CaseIterable {
    case goingOutside
    case running
    case cycling
    case walking
    case hiking
    case picnic
    case beach
    case outdoorDining
    case sightseeing
    case photography
    case gardening
    case swimming
    
    var localizedTitle: String {
        "activity_\(rawValue)"
    }
    
    var iconName: String {
        switch self {
        case .goingOutside: return "figure.outdoor"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .walking: return "figure.walk"
        case .hiking: return "figure.hiking"
        case .picnic: return "basket"
        case .beach: return "beach.umbrella"
        case .outdoorDining: return "fork.knife"
        case .sightseeing: return "binoculars"
        case .photography: return "camera.aperture"
        case .gardening: return "leaf"
        case .swimming: return "figure.pool.swim"
        }
    }
    
    var typicalDuration: TimeInterval {
        switch self {
        case .goingOutside: return 60 * 60
        case .running: return 30 * 60
        case .cycling: return 60 * 60
        case .walking: return 30 * 60
        case .hiking: return 120 * 60
        case .picnic: return 90 * 60
        case .beach: return 180 * 60
        case .outdoorDining: return 60 * 60
        case .sightseeing: return 180 * 60
        case .photography: return 60 * 60
        case .gardening: return 60 * 60
        case .swimming: return 60 * 60
        }
    }
    
    var windSensitivity: ActivitySensitivity {
        switch self {
        case .cycling, .photography: return .high
        case .running, .hiking, .picnic, .beach, .outdoorDining: return .medium
        case .goingOutside, .walking, .sightseeing, .gardening, .swimming: return .low
        }
    }
    
    var sunSensitivity: ActivitySensitivity {
        switch self {
        case .picnic, .beach, .gardening, .swimming: return .high
        case .running, .cycling, .hiking, .sightseeing, .photography: return .medium
        case .goingOutside, .walking, .outdoorDining: return .low
        }
    }
    
    var rainTolerance: ActivityTolerance {
        switch self {
        case .running, .cycling, .picnic, .beach, .outdoorDining, .photography, .swimming: return .low
        case .hiking, .walking, .sightseeing: return .medium
        case .goingOutside, .gardening: return .high
        }
    }
    
    var heatTolerance: ActivityTolerance {
        switch self {
        case .beach, .outdoorDining, .gardening, .swimming: return .high
        case .goingOutside, .running, .cycling, .hiking, .walking, .picnic, .sightseeing, .photography: return .medium
        }
    }
    
    var coldTolerance: ActivityTolerance {
        switch self {
        case .walking: return .high
        case .goingOutside, .running, .cycling, .hiking, .outdoorDining, .sightseeing, .photography, .gardening: return .medium
        case .picnic, .beach, .swimming: return .low
        }
    }
    
    var requiresDaylight: Bool {
        switch self {
        case .hiking, .picnic, .beach, .sightseeing, .gardening, .swimming: return true
        case .goingOutside, .running, .cycling, .walking, .outdoorDining, .photography: return false
        }
    }
    
    var category: ActivityCategory {
        switch self {
        case .running, .cycling, .walking, .hiking, .swimming: return .fitness
        case .picnic, .beach, .sightseeing: return .leisure
        case .outdoorDining: return .social
        case .photography: return .photography
        case .goingOutside, .gardening: return .outdoors
        }
    }
}
