import Foundation

/// Represents a notable weather event occurring during a specific time window today.
/// Examples: "Rain likely between 14:00–16:00", "Peak heat at 13:00 (36°C)", "Storm risk at evening"
struct DayKeyEvent: Identifiable, Equatable, Sendable {
    let id: String
    let type: EventType
    let startHour: Int
    let endHour: Int
    let title: String
    let description: String
    let symbolName: String
    let severity: EventSeverity

    enum EventType: String, Sendable, Equatable {
        case rain
        case heavyRain
        case storm
        case heat
        case cold
        case strongWind
        case highUV
        case bestWindow
    }

    enum EventSeverity: Int, Comparable, Sendable, Equatable {
        case low = 0
        case moderate = 1
        case high = 2
        case critical = 3

        static func < (lhs: EventSeverity, rhs: EventSeverity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Single hour display – shows only start time
    var isSingleHour: Bool {
        endHour - startHour <= 1
    }

    var timeDisplay: String {
        if isSingleHour {
            return String(format: "%02d:00", startHour)
        }
        return String(format: "%02d:00 – %02d:00", startHour, endHour)
    }
}
