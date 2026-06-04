import Foundation
import Testing
@testable import ForeWiz

struct JournalStoreTests {

    private func makeMockStore() -> MockJournalStore {
        MockJournalStore()
    }

    private func makeEntry(id: UUID = UUID(), title: String = "Test Trip", type: String = "trip", date: Date = Date()) -> JournalEntry {
        JournalEntry(
            id: id,
            date: date,
            title: title,
            locationName: "Istanbul",
            latitude: 41.0082,
            longitude: 28.9784,
            weatherSnapshotData: nil,
            routeData: nil,
            healthData: nil,
            notes: nil,
            createdAt: date,
            typeRaw: type
        )
    }

    // MARK: - CRUD

    @Test func saveAndFetchAll() async throws {
        let store = makeMockStore()
        let entry = makeEntry()
        try await store.save(entry)

        let all = try await store.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.id == entry.id)
    }

    @Test func saveMultipleAndFetchAll() async throws {
        let store = makeMockStore()
        try await store.save(makeEntry(id: UUID(), title: "Trip 1"))
        try await store.save(makeEntry(id: UUID(), title: "Trip 2"))
        try await store.save(makeEntry(id: UUID(), title: "Trip 3"))

        let all = try await store.fetchAll()
        #expect(all.count == 3)
    }

    @Test func fetchById() async throws {
        let store = makeMockStore()
        let id = UUID()
        try await store.save(makeEntry(id: id, title: "Specific Trip"))

        let fetched = try await store.fetch(by: id)
        #expect(fetched != nil)
        #expect(fetched?.title == "Specific Trip")
    }

    @Test func fetchByIdNotFound() async throws {
        let store = makeMockStore()
        let fetched = try await store.fetch(by: UUID())
        #expect(fetched == nil)
    }

    @Test func deleteEntry() async throws {
        let store = makeMockStore()
        let entry = makeEntry()
        try await store.save(entry)
        try await store.delete(entry)

        let all = try await store.fetchAll()
        #expect(all.isEmpty)
    }

    @Test func deleteById() async throws {
        let store = makeMockStore()
        let id = UUID()
        try await store.save(makeEntry(id: id))
        try await store.delete(id)

        let fetched = try await store.fetch(by: id)
        #expect(fetched == nil)
    }

    @Test func deleteNonExistentIsNoOp() async throws {
        let store = makeMockStore()
        try await store.save(makeEntry())
        // Deleting non-existent ID should not throw
        try await store.delete(UUID())
        let all = try await store.fetchAll()
        #expect(all.count == 1)
    }

    @Test func updateEntry() async throws {
        let store = makeMockStore()
        let id = UUID()
        var entry = makeEntry(id: id, title: "Original Title")
        try await store.save(entry)

        entry.title = "Updated Title"
        try await store.updateEntry(entry)

        let fetched = try await store.fetch(by: id)
        #expect(fetched?.title == "Updated Title")
    }

    @Test func updateNonExistentEntry() async throws {
        let store = makeMockStore()
        let entry = makeEntry()
        // Should not throw for mock
        try await store.updateEntry(entry)
    }

    // MARK: - Search

    @Test func searchByTitle() async throws {
        let store = makeMockStore()
        try await store.save(makeEntry(title: "Beach Day"))
        try await store.save(makeEntry(title: "Mountain Hike"))
        try await store.save(makeEntry(title: "City Tour"))

        let results = try await store.search(query: "Beach")
        #expect(results.count == 1)
        #expect(results.first?.title == "Beach Day")
    }

    @Test func searchByLocation() async throws {
        let store = makeMockStore()
        try await store.save(makeEntry(title: "Trip 1", date: Date()))
        let entry2 = JournalEntry(
            id: UUID(),
            date: Date(),
            title: "Ankara Visit",
            locationName: "Ankara",
            latitude: 39.9334,
            longitude: 32.8597,
            weatherSnapshotData: nil,
            routeData: nil,
            healthData: nil,
            notes: nil,
            createdAt: Date(),
            typeRaw: "trip"
        )
        try await store.save(entry2)

        let results = try await store.search(query: "Ankara")
        #expect(results.count == 1)
        #expect(results.first?.title == "Ankara Visit")
    }

    @Test func searchByNotes() async throws {
        let store = makeMockStore()
        let entry = JournalEntry(
            id: UUID(),
            date: Date(),
            title: "Random Trip",
            locationName: "Istanbul",
            latitude: 41.0082,
            longitude: 28.9784,
            weatherSnapshotData: nil,
            routeData: nil,
            healthData: nil,
            notes: "Had a wonderful time exploring the Bosphorus",
            createdAt: Date(),
            typeRaw: "trip"
        )
        try await store.save(entry)

        let results = try await store.search(query: "Bosphorus")
        #expect(results.count == 1)
    }

    @Test func searchEmptyQueryReturnsAll() async throws {
        let store = makeMockStore()
        try await store.save(makeEntry(title: "A"))
        try await store.save(makeEntry(title: "B"))
        try await store.save(makeEntry(title: "C"))

        let results = try await store.search(query: "")
        #expect(results.count == 3)
    }

    @Test func searchNoResults() async throws {
        let store = makeMockStore()
        try await store.save(makeEntry(title: "Istanbul Trip"))

        let results = try await store.search(query: "NonExistentQuery12345")
        #expect(results.isEmpty)
    }

    @Test func searchCaseInsensitive() async throws {
        let store = makeMockStore()
        try await store.save(makeEntry(title: "Beach Paradise"))

        let lower = try await store.search(query: "beach")
        let upper = try await store.search(query: "BEACH")
        let mixed = try await store.search(query: "Beach")

        #expect(lower.count == 1)
        #expect(upper.count == 1)
        #expect(mixed.count == 1)
    }

    // MARK: - Date Range

    @Test func fetchByDateRange() async throws {
        let store = makeMockStore()
        let calendar = Calendar.current
        let today = Date()

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        try await store.save(makeEntry(id: UUID(), title: "Yesterday", date: yesterday))
        try await store.save(makeEntry(id: UUID(), title: "Two Days Ago", date: twoDaysAgo))
        try await store.save(makeEntry(id: UUID(), title: "Today", date: today))

        let results = try await store.fetch(from: twoDaysAgo, to: today)
        #expect(results.count == 3)
    }

    @Test func fetchByDateRangeFiltersCorrectly() async throws {
        let store = makeMockStore()
        let calendar = Calendar.current
        let today = Date()

        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        try await store.save(makeEntry(id: UUID(), title: "Old", date: lastWeek))
        try await store.save(makeEntry(id: UUID(), title: "Today", date: today))

        // Fetch only recent
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let results = try await store.fetch(from: threeDaysAgo, to: today)
        #expect(results.count == 1)
        #expect(results.first?.title == "Today")
    }

    // MARK: - Edge Cases

    @Test func emptyStore() async throws {
        let store = makeMockStore()
        let all = try await store.fetchAll()
        #expect(all.isEmpty)
    }

    @Test func multipleDeletes() async throws {
        let store = makeMockStore()
        let id1 = UUID()
        let id2 = UUID()
        try await store.save(makeEntry(id: id1))
        try await store.save(makeEntry(id: id2))

        try await store.delete(id1)
        try await store.delete(id2)

        let all = try await store.fetchAll()
        #expect(all.isEmpty)
    }

    @Test func journalEntryTypeRoundTrip() async throws {
        let store = makeMockStore()
        let trip = makeEntry(type: "trip")
        let commute = makeEntry(id: UUID(), title: "Work Commute", type: "commute")
        let explore = makeEntry(id: UUID(), title: "Weekend Explore", type: "explore")

        try await store.save(trip)
        try await store.save(commute)
        try await store.save(explore)

        let all = try await store.fetchAll()
        #expect(all.count == 3)
        #expect(all.contains { $0.typeRaw == "trip" })
        #expect(all.contains { $0.typeRaw == "commute" })
        #expect(all.contains { $0.typeRaw == "explore" })
    }
}
