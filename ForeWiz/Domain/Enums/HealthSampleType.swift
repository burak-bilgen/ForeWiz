import Foundation

enum HealthSampleType: String, CaseIterable, Codable, Sendable {
    case heartRate
    case restingHeartRate
    case sleepHours
    case steps
    case respiratoryRate
    case uvExposure
    
    var localizedTitle: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .sleepHours: return "Sleep"
        case .steps: return "Steps"
        case .respiratoryRate: return "Respiratory Rate"
        case .uvExposure: return "UV Exposure"
        }
    }
    
    var unit: String {
        switch self {
        case .heartRate, .restingHeartRate: return "bpm"
        case .sleepHours: return "hours"
        case .steps: return "count"
        case .respiratoryRate: return "breaths/min"
        case .uvExposure: return "UV index"
        }
    }
}
