import Foundation

protocol WeatherCacheRepository {
    func loadLatest() async throws -> WeatherSnapshot?
    func save(_ snapshot: WeatherSnapshot) async throws
    func deleteAll() async throws
}
