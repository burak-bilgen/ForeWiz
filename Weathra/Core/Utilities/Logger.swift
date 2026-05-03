import OSLog

enum AppLogger {
    static let app = Logger(subsystem: "com.weathra.app", category: "app")
    static let weather = Logger(subsystem: "com.weathra.app", category: "weather")
    static let notifications = Logger(subsystem: "com.weathra.app", category: "notifications")
}
