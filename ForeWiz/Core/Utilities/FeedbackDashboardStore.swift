import Foundation
import OSLog

@MainActor
@Observable
final class FeedbackDashboardStore {
    static let shared = FeedbackDashboardStore()

    private(set) var items: [FeedbackDashboardItem] = []
    private(set) var unreadCount: Int = 0

    private let userDefaults: UserDefaults
    private let storageKey = "feedback_dashboard_items_v1"

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func addItem(type: String, title: String, message: String, success: Bool) {
        let item = FeedbackDashboardItem(
            id: UUID(),
            type: type,
            title: title,
            message: message,
            submittedAt: Date(),
            success: success,
            isRead: false
        )
        items.insert(item, at: 0)
        unreadCount = items.filter { !$0.isRead }.count
        save()

        AppLogger.app.info("[Dashboard] Feedback saved locally: \(title)")
    }

    func markAllRead() {
        for i in items.indices {
            items[i].isRead = true
        }
        unreadCount = 0
        save()
    }

    func markRead(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isRead = true
        unreadCount = items.filter { !$0.isRead }.count
        save()
    }

    func removeAll() {
        items.removeAll()
        unreadCount = 0
        save()
    }

    func removeItems(at indexSet: IndexSet) {
        let idsToRemove = indexSet.map { items[$0].id }
        items.removeAll { idsToRemove.contains($0.id) }
        unreadCount = items.filter { !$0.isRead }.count
        save()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FeedbackDashboardItem].self, from: data) else { return }
        items = decoded
        unreadCount = items.filter { !$0.isRead }.count
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}

struct FeedbackDashboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let type: String
    let title: String
    let message: String
    let submittedAt: Date
    let success: Bool
    var isRead: Bool
}
