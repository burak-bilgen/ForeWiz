import Foundation

enum SharedFormatters {
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static let dateAndTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM HH:mm"
        return f
    }()
}
