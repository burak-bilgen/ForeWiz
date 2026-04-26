import OSLog

enum AppLogger {
    static let app = Logger(subsystem: "com.havaasistani.app", category: "app")
    static let weather = Logger(subsystem: "com.havaasistani.app", category: "weather")
    static let notifications = Logger(subsystem: "com.havaasistani.app", category: "notifications")
}
