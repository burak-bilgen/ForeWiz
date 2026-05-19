import Foundation
import UIKit
import OSLog

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
