import Foundation

struct ChartDataPoint {
    let hour: Int
    let value: Double
    let index: Int
}

struct ComfortWindow {
    let startHour: Int
    var endHour: Int?
    let score: Int
    let level: ComfortLevel

    init(startHour: Int, endHour: Int? = nil, score: Int, level: ComfortLevel) {
        self.startHour = startHour
        self.endHour = endHour
        self.score = score
        self.level = level
    }
}
