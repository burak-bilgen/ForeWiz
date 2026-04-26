import Foundation

struct WeatherScore: Codable, Equatable, Hashable, Sendable {
    let rawValue: Int
    let label: String

    var displayValue: Double {
        Double(rawValue) / 10
    }

    init(rawValue: Int, label: String? = nil) {
        let clampedValue = rawValue.clamped(to: 0...100)
        self.rawValue = clampedValue
        self.label = label ?? Self.defaultLabel(for: clampedValue)
    }

    private static func defaultLabel(for value: Int) -> String {
        switch value {
        case 80...100:
            "Çok iyi"
        case 60..<80:
            "Uygun"
        case 40..<60:
            "Dikkatli"
        default:
            "Kaçın"
        }
    }
}
