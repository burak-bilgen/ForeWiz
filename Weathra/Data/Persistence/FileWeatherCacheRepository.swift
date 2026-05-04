import Foundation

final class FileWeatherCacheRepository: WeatherCacheRepository {
    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let filename = "weather_snapshot.json"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = urls[0].appendingPathComponent("com.weathra.cache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func loadLatest() async throws -> WeatherSnapshot? {
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let stored = try JSONDecoder().decode(StoredWeatherSnapshot.self, from: data)
            return stored.snapshot
        } catch {
            throw AppError.cacheUnavailable
        }
    }

    func save(_ snapshot: WeatherSnapshot) async throws {
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        do {
            let data = try JSONEncoder().encode(StoredWeatherSnapshot(snapshot: snapshot))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw AppError.cacheUnavailable
        }
    }
}
