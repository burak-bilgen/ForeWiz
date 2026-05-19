import Foundation
import UIKit
import UserNotifications
import OSLog

final class AppLifecycleManager {
    static let shared = AppLifecycleManager()
    private let logger = AppLogger.lifecycle

    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var stateHistory: [AppStateTransition] = []
    private let maxHistorySize = 50

    private init() {}

    func applicationDidEnterBackground() {
        logger.info("App entered background")

        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }

        BackgroundRefreshManager.shared.scheduleAppRefresh()
        BackgroundRefreshManager.shared.scheduleProcessingTask()

        logStateTransition(from: .active, to: .background)
    }

    func applicationWillEnterForeground() {
        logger.info("App will enter foreground")

        endBackgroundTask()

        logStateTransition(from: .background, to: .foreground)

        NotificationCenter.default.post(name: .appWillEnterForeground, object: nil)
    }

    func applicationDidBecomeActive() {
        logger.info("App became active")

        logStateTransition(from: .inactive, to: .active)

        UNUserNotificationCenter.current().setBadgeCount(0)

        NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
    }

    func applicationWillResignActive() {
        logger.info("App will resign active")

        logStateTransition(from: .active, to: .inactive)
    }

    func applicationWillTerminate() {
        logger.info("App will terminate")

        logStateTransition(from: .active, to: .terminated)

        BackgroundRefreshManager.shared.cancelAllTasks()
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            logger.info("Background task ended")
        }
    }

    private func logStateTransition(from: AppState, to: AppState) {
        let transition = AppStateTransition(
            from: from,
            to: to,
            timestamp: Date()
        )

        stateHistory.append(transition)

        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst(stateHistory.count - maxHistorySize)
        }

        logger.debug("State transition: \(from.rawValue) -> \(to.rawValue)")
    }

    var recentStateHistory: [AppStateTransition] {
        Array(stateHistory.suffix(10))
    }
}

enum AppState: String {
    case active, inactive, background, foreground, terminated
}

struct AppStateTransition {
    let from: AppState
    let to: AppState
    let timestamp: Date
}

extension Notification.Name {
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
    static let weatherDataDidUpdate = Notification.Name("weatherDataDidUpdate")
    static let userPreferencesDidChange = Notification.Name("userPreferencesDidChange")
}
