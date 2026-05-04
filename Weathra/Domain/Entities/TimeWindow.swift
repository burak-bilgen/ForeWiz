import Foundation

struct TimeWindow: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let start: Date
    let end: Date

    init(start: Date, end: Date, id: String? = nil) {
        self.start = start
        self.end = end
        self.id = id ?? "\(Int(start.timeIntervalSince1970))-\(Int(end.timeIntervalSince1970))"
    }

    var shortDisplayText: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: start))–\(formatter.string(from: end))"
    }

    func containsClockTime(of date: Date, calendar: Calendar) -> Bool {
        let startMinutes = calendar.component(.hour, from: start) * 60 + calendar.component(.minute, from: start)
        let endMinutes = calendar.component(.hour, from: end) * 60 + calendar.component(.minute, from: end)
        let dateMinutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)

        if startMinutes <= endMinutes {
            return dateMinutes >= startMinutes && dateMinutes < endMinutes
        }

        return dateMinutes >= startMinutes || dateMinutes < endMinutes
    }

    static func previewQuietHours() -> TimeWindow {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now
        let end = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
        return TimeWindow(start: start, end: end, id: "quiet-hours-preview")
    }

}
