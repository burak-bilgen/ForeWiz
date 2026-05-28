import Foundation
import SwiftData

@MainActor
final class SwiftDataWeatherCacheRepository: WeatherCacheRepository {
    private let modelContext: ModelContext
    private let cachePolicy: WeatherCachePolicy

    init(modelContext: ModelContext, cachePolicy: WeatherCachePolicy = .init()) {
        self.modelContext = modelContext
        self.cachePolicy = cachePolicy
    }

    func loadLatest() async throws -> WeatherSnapshot? {
        let descriptor = FetchDescriptor<WeatherSnapshotModel>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            return nil
        }
        
        let snapshot = try model.toSnapshot()
        
        if cachePolicy.freshness(for: snapshot.fetchedAt, now: Date()) == .expired {
            modelContext.delete(model)
            try modelContext.save()
            return nil
        }
        
        return snapshot
    }

    func save(_ snapshot: WeatherSnapshot) async throws {
        let descriptor = FetchDescriptor<WeatherSnapshotModel>()
        let existing = try modelContext.fetch(descriptor)
        
        existing.forEach { modelContext.delete($0) }
        
        let model = try WeatherSnapshotModel(snapshot: snapshot)
        modelContext.insert(model)
        try modelContext.save()
    }

    func deleteAll() async throws {
        let descriptor = FetchDescriptor<WeatherSnapshotModel>()
        let models = try modelContext.fetch(descriptor)
        models.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}
