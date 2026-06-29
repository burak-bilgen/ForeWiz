import Foundation

struct HealthSample: Codable, Equatable, Sendable {
    let type: HealthSampleType
    let value: Double
    let unit: String
    let date: Date
    let source: String?

    init(type: HealthSampleType, value: Double, unit: String? = nil, date: Date, source: String? = nil) {
        self.type = type
        self.value = value
        self.unit = unit ?? type.unit
        self.date = date
        self.source = source
    }
}
