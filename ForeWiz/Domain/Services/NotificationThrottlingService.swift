import Foundation

final class NotificationThrottlingService: @unchecked Sendable {
    private let defaults: UserDefaults
    private let lock = NSLock()

    private static let cooldowns: [NotificationCategory: TimeInterval] = [
        .morningBriefing: 23 * 3600,
        .weatherAlert: 4 * 3600,
    ]

    private static let dailyLimits: [NotificationCategory: Int] = [
        .morningBriefing: 1,
        .weatherAlert: 4,
    ]

    private static let sentTimestampsKey = "notif_throttle_sent_timestamps"
    private static let dailyCountKeyPrefix = "notif_throttle_daily_count_"
    private static let contentHashKeyPrefix = "notif_throttle_content_"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func throttle(_ plans: [NotificationPlan], now: Date = Date()) -> [NotificationPlan] {
        lock.lock()
        defer { lock.unlock() }

        let todayKey = dailyKey(for: now)

        return plans.filter { plan in
            guard allowedByCooldown(plan) else { return false }
            guard allowedByDailyLimit(plan, todayKey: todayKey) else { return false }
            guard allowedByContentDeduplication(plan) else { return false }
            return true
        }
    }

    func didSchedule(_ plans: [NotificationPlan], now: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }

        let todayKey = dailyKey(for: now)

        for plan in plans {
            recordCooldown(plan, now: now)
            incrementDailyCount(plan, todayKey: todayKey)
            recordContentHash(plan, now: now)
        }
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }

        let dict = defaults.dictionaryRepresentation()
        for key in dict.keys where key.hasPrefix("notif_throttle_") {
            defaults.removeObject(forKey: key)
        }
    }

    private func allowedByCooldown(_ plan: NotificationPlan) -> Bool {
        let cooldown = Self.cooldowns[plan.category] ?? 0
        guard cooldown > 0 else { return true }

        guard let lastSent = lastSentDate(for: plan.category) else { return true }
        return Date().timeIntervalSince(lastSent) >= cooldown
    }

    private func lastSentDate(for category: NotificationCategory) -> Date? {
        let timestamps = defaults.dictionary(forKey: Self.sentTimestampsKey) as? [String: TimeInterval] ?? [:]
        return timestamps[category.rawValue].map { Date(timeIntervalSince1970: $0) }
    }

    private func recordCooldown(_ plan: NotificationPlan, now: Date) {
        var timestamps = defaults.dictionary(forKey: Self.sentTimestampsKey) as? [String: TimeInterval] ?? [:]
        timestamps[plan.category.rawValue] = now.timeIntervalSince1970
        defaults.set(timestamps, forKey: Self.sentTimestampsKey)
    }

    private func allowedByDailyLimit(_ plan: NotificationPlan, todayKey: String) -> Bool {
        let limit = Self.dailyLimits[plan.category] ?? Int.max
        guard limit < Int.max else { return true }
        let count = dailyCount(for: plan.category, todayKey: todayKey)
        return count < limit
    }

    private func dailyCount(for category: NotificationCategory, todayKey: String) -> Int {
        let key = "\(Self.dailyCountKeyPrefix)\(category.rawValue)_\(todayKey)"
        return defaults.integer(forKey: key)
    }

    private func incrementDailyCount(_ plan: NotificationPlan, todayKey: String) {
        let key = "\(Self.dailyCountKeyPrefix)\(plan.category.rawValue)_\(todayKey)"
        let current = defaults.integer(forKey: key)
        defaults.set(current + 1, forKey: key)
    }

    private func allowedByContentDeduplication(_ plan: NotificationPlan) -> Bool {
        let hash = contentHash(plan)
        let todayKey = dailyKey(for: Date())
        let key = "\(Self.contentHashKeyPrefix)\(hash)_\(todayKey)"
        return !defaults.bool(forKey: key)
    }

    private func recordContentHash(_ plan: NotificationPlan, now: Date) {
        let hash = contentHash(plan)
        let todayKey = dailyKey(for: now)
        let key = "\(Self.contentHashKeyPrefix)\(hash)_\(todayKey)"
        defaults.set(true, forKey: key)
    }

    private func contentHash(_ plan: NotificationPlan) -> String {
        let raw = "\(plan.category.rawValue)|\(plan.title)|\(plan.body)"
        return String(raw.hashValue)
    }

    private func dailyKey(for date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }
}
