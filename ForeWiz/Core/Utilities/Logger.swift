import OSLog
import Foundation

/// Centralized loggers for each subsystem.
enum AppLogger {
    static let app = Logger(subsystem: "com.forewiz.app", category: "app")
    static let weather = Logger(subsystem: "com.forewiz.app", category: "weather")
    static let notifications = Logger(subsystem: "com.forewiz.app", category: "notifications")
    static let location = Logger(subsystem: "com.forewiz.app", category: "location")
    static let persistence = Logger(subsystem: "com.forewiz.app", category: "persistence")
    static let network = Logger(subsystem: "com.forewiz.app", category: "network")
    static let performance = Logger(subsystem: "com.forewiz.app", category: "performance")
    static let analytics = Logger(subsystem: "com.forewiz.app", category: "analytics")
    static let ui = Logger(subsystem: "com.forewiz.app", category: "ui")
    static let lifecycle = Logger(subsystem: "com.forewiz.app", category: "lifecycle")
    static let cache = Logger(subsystem: "com.forewiz.app", category: "cache")
    static let widget = Logger(subsystem: "com.forewiz.app", category: "widget")
    static let shortcuts = Logger(subsystem: "com.forewiz.app", category: "shortcuts")
    static let wizPath = Logger(subsystem: "com.forewiz.app", category: "wizpath")
    static let search = Logger(subsystem: "com.forewiz.app", category: "search")
}

enum LogLevel: String, CaseIterable {
    case debug, info, warning, error, critical

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

/// Convenience logging methods that include source file/line information.
enum AppLog {
    static func debug(_ message: String, metadata: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        AppLogger.app.debug("\\((file as NSString).lastPathComponent):\(line) \(function) - \(message, privacy: .private)")
    }

    static func info(_ message: String, metadata: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        AppLogger.app.info("\\((file as NSString).lastPathComponent):\(line) \(function) - \(message, privacy: .private)")
    }

    static func warning(_ message: String, metadata: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        AppLogger.app.warning("\\((file as NSString).lastPathComponent):\(line) \(function) - \(message, privacy: .private)")
    }

    static func error(_ message: String, metadata: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        AppLogger.app.error("\\((file as NSString).lastPathComponent):\(line) \(function) - \(message, privacy: .private)")
    }

    static func performance(operation: String, duration: TimeInterval, file: String = #file, function: String = #function, line: Int = #line) {
        AppLogger.performance.info("\\((file as NSString).lastPathComponent):\(line) \(operation) completed in \(String(format: "%.3f", duration))s")
    }

    @discardableResult
    static func measure<T>(operation: String, file: String = #file, function: String = #function, line: Int = #line, _ block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let diff = CFAbsoluteTimeGetCurrent() - start
        performance(operation: operation, duration: diff, file: file, function: function, line: line)
        return result
    }

    @discardableResult
    static func measureAsync<T>(operation: String, file: String = #file, function: String = #function, line: Int = #line, _ block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let diff = CFAbsoluteTimeGetCurrent() - start
        performance(operation: operation, duration: diff, file: file, function: function, line: line)
        return result
    }
}

extension AppLogger {
    static func logError(_ error: Error, category: String = "app", file: String = #file, function: String = #function, line: Int = #line) {
        let logger = Logger(subsystem: "com.forewiz.app", category: category)
        let fileName = (file as NSString).lastPathComponent
        logger.error("Error at \(fileName):\(line) in \(function): \(error.localizedDescription, privacy: .private)")

        if let appError = error as? AppError {
            logger.error("AppError details: \(String(describing: appError), privacy: .private)")
        }
    }

    static func logNetworkRequest(_ request: URLRequest, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"
        AppLogger.network.debug("[\(fileName):\(line)] \(method) \(url)")
    }

    static func logCacheOperation(_ operation: String, key: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        AppLogger.cache.info("[\(fileName):\(line)] \(operation) - key: \(key, privacy: .private)")
    }

    static func logLifecycle(_ event: String, object: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        AppLogger.lifecycle.debug("[\(fileName):\(line)] \(event) - \(object, privacy: .private)")
    }
}
