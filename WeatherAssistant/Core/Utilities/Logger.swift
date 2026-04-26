import OSLog

enum AppLogger {
    static let app = Logger(subsystem: "com.weatherassistant.app", category: "app")
    static let weather = Logger(subsystem: "com.weatherassistant.app", category: "weather")
    static let notifications = Logger(subsystem: "com.weatherassistant.app", category: "notifications")
}
