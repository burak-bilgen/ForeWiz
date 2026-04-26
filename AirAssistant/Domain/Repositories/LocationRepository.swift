import Foundation

protocol LocationRepository {
    func requestAuthorization() async -> LocationAuthorizationStatus
    func getCurrentLocation() async throws -> LocationCoordinate
}
