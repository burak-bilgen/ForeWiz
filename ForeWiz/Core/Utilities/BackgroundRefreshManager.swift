import Foundation
import BackgroundTasks
import Network
import UIKit
import OSLog
import UserNotifications
import WidgetKit

final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    private let logger = AppLogger.lifecycle

    private let refreshTaskIdentifier = "com.forewiz.backgroundrefresh"
    private let processingTaskIdentifier = "com.forewiz.backgroundprocessing"

    private var isRegistered = false

    private init() {}

    func registerTasks() {
        guard !isRegistered else { return }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            self.handleAppRefresh(task: task)
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingTaskIdentifier, using: nil) { task in
            guard let task = task as? BGProcessingTask else { return }
            self.handleProcessingTask(task: task)
        }

        isRegistered = true
        logger.info("Background tasks registered")
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled background app refresh")
        } catch {
            logger.error("Failed to schedule app refresh: \(error.localizedDescription)")
        }
    }

    func scheduleProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: processingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled background processing task")
        } catch {
            logger.error("Failed to schedule processing task: \(error.localizedDescription)")
        }
    }

    func cancelAllTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: processingTaskIdentifier)
        logger.info("All background tasks cancelled")
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        logger.info("Handling background app refresh")

        scheduleAppRefresh()

        let refreshTask = Task {
            let success = await self.performBackgroundRefresh()
            task.setTaskCompleted(success: success && !Task.isCancelled)
            self.logger.info("Background refresh completed with success: \(success)")
        }

        task.expirationHandler = { [weak self] in
            self?.logger.warning("Background refresh task expired")
            refreshTask.cancel()
        }
    }

    private func handleProcessingTask(task: BGProcessingTask) {
        logger.info("Handling background processing task")

        scheduleProcessingTask()

        let processingTask = Task {
            let success = await self.performBackgroundProcessing()
            task.setTaskCompleted(success: success && !Task.isCancelled)
            self.logger.info("Background processing completed with success: \(success)")
        }

        task.expirationHandler = { [weak self] in
            self?.logger.warning("Background processing task expired")
            processingTask.cancel()
        }
    }

    @MainActor
    private func performBackgroundRefresh() async -> Bool {
        do {
            let container = try await ContainerProvider.shared.container

            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: true)

            _ = try await container.scheduleSmartNotificationsUseCase.execute(
                recommendation: result.recommendation,
                profile: try await container.preferencesRepository.loadProfile()
            )

            WidgetCenter.shared.reloadAllTimelines()

            logger.info("Background refresh completed successfully")
            return true
        } catch {
            logger.error("Background refresh failed: \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    private func performBackgroundProcessing() async -> Bool {
        logger.info("Performing background processing")

        do {
            let container = try await ContainerProvider.shared.container

            let snapshot = try await container.weatherCacheRepository.loadLatest()

            if snapshot == nil {
                logger.info("No cached weather data, performing refresh")
                _ = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: true)
            }

            cleanupOldCacheData()

            logger.info("Background processing completed")
            return true
        } catch {
            logger.error("Background processing failed: \(error.localizedDescription)")
            return false
        }
    }

    private func cleanupOldCacheData() {
        let fileManager = FileManager.default
        guard let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }

        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.contentModificationDateKey])

            let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)

            for fileURL in contents {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let modificationDate = attributes[.modificationDate] as? Date,
                   modificationDate < oneWeekAgo {
                    try? fileManager.removeItem(at: fileURL)
                    logger.debug("Cleaned up old cache file: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            logger.error("Cache cleanup failed: \(error.localizedDescription)")
        }
    }
}

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

final class RefreshController {
    static let shared = RefreshController()
    private let logger = AppLogger.lifecycle

    private var lastRefreshTime: Date?
    private let minimumRefreshInterval: TimeInterval = 300

    private var isRefreshing = false
    private let refreshLock = NSLock()

    private var scheduledRefreshWorkItem: DispatchWorkItem?

    private init() {}

    private enum RefreshStartDecision {
        case started
        case alreadyRefreshing
        case throttled(TimeInterval)
    }

    var canRefresh: Bool {
        guard let lastRefresh = lastRefreshTime else { return true }
        return Date().timeIntervalSince(lastRefresh) >= minimumRefreshInterval
    }

    var timeUntilNextRefresh: TimeInterval {
        guard let lastRefresh = lastRefreshTime else { return 0 }
        let elapsed = Date().timeIntervalSince(lastRefresh)
        return max(0, minimumRefreshInterval - elapsed)
    }

    func performRefresh(force: Bool = false) async -> Bool {
        switch beginRefresh(force: force) {
        case .started:
            break
        case .alreadyRefreshing:
            logger.warning("Refresh already in progress, skipping")
            return false
        case .throttled(let waitTime):
            logger.info("Refresh throttled, must wait \(Int(waitTime)) seconds")
            return false
        }

        defer { finishRefresh() }

        do {
            logger.info("Starting manual refresh")

            let container = try await ContainerProvider.shared.container
            let result = try await container.loadHomeRecommendationUseCase.execute(forceRefresh: true)

            NotificationCenter.default.post(
                name: .weatherDataDidUpdate,
                object: result
            )

            logger.info("Manual refresh completed successfully")
            return true
        } catch {
            logger.error("Manual refresh failed: \(error.localizedDescription)")
            return false
        }
    }

    private func beginRefresh(force: Bool) -> RefreshStartDecision {
        refreshLock.lock()
        defer { refreshLock.unlock() }

        guard !isRefreshing else {
            return .alreadyRefreshing
        }

        if !force && !canRefresh {
            return .throttled(timeUntilNextRefresh)
        }

        isRefreshing = true
        return .started
    }

    private func finishRefresh() {
        refreshLock.lock()
        isRefreshing = false
        lastRefreshTime = Date()
        refreshLock.unlock()
    }

    func scheduleRefresh(after delay: TimeInterval) {
        scheduledRefreshWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task {
                _ = await self?.performRefresh()
            }
        }

        scheduledRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)

        logger.info("Refresh scheduled in \(Int(delay)) seconds")
    }

    func cancelScheduledRefresh() {
        scheduledRefreshWorkItem?.cancel()
        scheduledRefreshWorkItem = nil
        logger.info("Scheduled refresh cancelled")
    }
}

final class NetworkConnectivityMonitor {
    static let shared = NetworkConnectivityMonitor()
    private let logger = AppLogger.network
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.forewiz.network-monitor", qos: .utility)
    private var isMonitoring = false
    private var lastKnownStatus: NetworkStatus = .unknown

    private init() {}

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitor.pathUpdateHandler = { [weak self] path in
            let newStatus: NetworkStatus = path.status == .satisfied ? .reachable : .notReachable
            let oldStatus = self?.lastKnownStatus ?? .unknown
            if newStatus != oldStatus {
                self?.logger.info("Network status changed: \(oldStatus.rawValue) -> \(newStatus.rawValue)")
                self?.lastKnownStatus = newStatus
                if newStatus == .reachable {
                    NotificationCenter.default.post(name: .networkDidBecomeReachable, object: nil)
                } else {
                    NotificationCenter.default.post(name: .networkDidBecomeUnreachable, object: nil)
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }

    var currentStatus: NetworkStatus {
        monitor.currentPath.status == .satisfied ? .reachable : .notReachable
    }

    var isReachable: Bool {
        currentStatus == .reachable
    }
}

enum NetworkStatus: String {
    case reachable, notReachable, unknown
}

extension Notification.Name {
    static let networkDidBecomeReachable = Notification.Name("networkDidBecomeReachable")
    static let networkDidBecomeUnreachable = Notification.Name("networkDidBecomeUnreachable")
}

final class BatteryAwareRefreshManager {
    static let shared = BatteryAwareRefreshManager()
    private let logger = AppLogger.lifecycle

    private var batteryLevel: Float {
        UIDevice.current.batteryLevel
    }

    private var batteryState: UIDevice.BatteryState {
        UIDevice.current.batteryState
    }

    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    deinit {
        UIDevice.current.isBatteryMonitoringEnabled = false
    }

    var shouldAllowBackgroundRefresh: Bool {
        let level = batteryLevel
        let state = batteryState

        if state == .charging || state == .full {
            return true
        }

        if level < 0 {
            return true
        }

        return level > 0.20
    }

    var refreshFrequency: TimeInterval {
        let level = batteryLevel
        let state = batteryState

        if state == .charging || state == .full {
            return 15 * 60
        }

        if level < 0.10 {
            return 60 * 60
        } else if level < 0.20 {
            return 30 * 60
        } else {
            return 15 * 60
        }
    }

    func logBatteryStatus() {
        let level = Int(batteryLevel * 100)
        let state = batteryState
        let allowed = shouldAllowBackgroundRefresh
        let frequency = refreshFrequency / 60

        logger.info("Battery: \(level)%, State: \(state)")
        logger.info("Background refresh allowed: \(allowed)")
        logger.info("Refresh frequency: \(frequency) minutes")
    }
}

extension UIDevice.BatteryState: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        @unknown default: return "unknown"
        }
    }
}
