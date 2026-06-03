import Foundation
import SwiftData

// MARK: - Protocol

protocol JournalStore {
    func save(_ entry: JournalEntry) async throws
    func fetchAll() async throws -> [JournalEntry]
    func fetch(by id: UUID) async throws -> JournalEntry?
    func fetch(from startDate: Date, to endDate: Date) async throws -> [JournalEntry]
    func search(query: String) async throws -> [JournalEntry]
    func delete(_ entry: JournalEntry) async throws
    func delete(_ id: UUID) async throws
    func updateEntry(_ entry: JournalEntry) async throws
}

// MARK: - Default Implementation

@MainActor
final class DefaultJournalStore: JournalStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ entry: JournalEntry) async throws {
        let model = JournalEntryModel(from: entry)
        modelContext.insert(model)
        try modelContext.save()
    }

    func fetchAll() async throws -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntryModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toJournalEntry() }
    }

    func fetch(by id: UUID) async throws -> JournalEntry? {
        var descriptor = FetchDescriptor<JournalEntryModel>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        let models = try modelContext.fetch(descriptor)
        return models.first?.toJournalEntry()
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntryModel>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toJournalEntry() }
    }

    func search(query: String) async throws -> [JournalEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return try await fetchAll()
        }
        let descriptor = FetchDescriptor<JournalEntryModel>(
            predicate: #Predicate {
                $0.title.localizedStandardContains(trimmed)
                || $0.locationName?.localizedStandardContains(trimmed) == true
                || $0.notes?.localizedStandardContains(trimmed) == true
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toJournalEntry() }
    }

    func delete(_ entry: JournalEntry) async throws {
        try await delete(entry.id)
    }

    func delete(_ id: UUID) async throws {
        var descriptor = FetchDescriptor<JournalEntryModel>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let model = try modelContext.fetch(descriptor).first else {
            throw JournalStoreError.notFound(id)
        }
        modelContext.delete(model)
        try modelContext.save()
    }

    func updateEntry(_ entry: JournalEntry) async throws {
        var descriptor = FetchDescriptor<JournalEntryModel>(
            predicate: #Predicate { $0.id == entry.id }
        )
        descriptor.fetchLimit = 1
        guard let existingModel = try modelContext.fetch(descriptor).first else {
            throw JournalStoreError.notFound(entry.id)
        }

        existingModel.title = entry.title
        existingModel.date = entry.date
        existingModel.locationName = entry.locationName
        existingModel.latitude = entry.latitude
        existingModel.longitude = entry.longitude
        existingModel.weatherSnapshotData = entry.weatherSnapshotData
        existingModel.routeData = entry.routeData
        existingModel.healthData = entry.healthData
        existingModel.notes = entry.notes
        existingModel.typeRaw = entry.typeRaw

        try modelContext.save()
    }
}

// MARK: - Errors

enum JournalStoreError: LocalizedError {
    case notFound(UUID)

    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Journal entry with id \(id) not found."
        }
    }
}

// MARK: - Mock for Previews

final class MockJournalStore: JournalStore, @unchecked Sendable {
    private var entries: [JournalEntry] = []
    private let lock = NSLock()

    func save(_ entry: JournalEntry) async throws {
        lock.lock()
        entries.append(entry)
        lock.unlock()
    }

    func fetchAll() async throws -> [JournalEntry] {
        lock.lock()
        let sorted = entries.sorted { $0.date > $1.date }
        lock.unlock()
        return sorted
    }

    func fetch(by id: UUID) async throws -> JournalEntry? {
        lock.lock()
        let result = entries.first { $0.id == id }
        lock.unlock()
        return result
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [JournalEntry] {
        lock.lock()
        let result = entries.filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date > $1.date }
        lock.unlock()
        return result
    }

    func search(query: String) async throws -> [JournalEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try await fetchAll() }
        lock.lock()
        let result = entries.filter {
            $0.title.localizedStandardContains(trimmed)
            || $0.locationName?.localizedStandardContains(trimmed) == true
            || $0.notes?.localizedStandardContains(trimmed) == true
        }
        .sorted { $0.date > $1.date }
        lock.unlock()
        return result
    }

    func delete(_ entry: JournalEntry) async throws {
        try await delete(entry.id)
    }

    func delete(_ id: UUID) async throws {
        lock.lock()
        entries.removeAll { $0.id == id }
        lock.unlock()
    }

    func updateEntry(_ entry: JournalEntry) async throws {
        lock.lock()
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        }
        lock.unlock()
    }
}
