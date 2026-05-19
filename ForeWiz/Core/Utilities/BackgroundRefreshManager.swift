import Foundation
import BackgroundTasks
import UIKit
import OSLog
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
