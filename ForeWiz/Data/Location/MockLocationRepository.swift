import Foundation

final class MockLocationRepository: LocationRepository {
    func requestAuthorization() async -> LocationAuthorizationStatus {
        .authorized
    }

    func getCurrentLocation() async throws -> LocationCoordinate {
        LocationCoordinate(latitude: 41.0082, longitude: 28.9784)
    }
}
