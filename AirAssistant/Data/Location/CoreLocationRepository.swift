import Foundation

final class CoreLocationRepository: LocationRepository {
    func requestAuthorization() async -> LocationAuthorizationStatus {
        .notDetermined
    }

    func getCurrentLocation() async throws -> LocationCoordinate {
        throw AppError.locationUnavailable
    }
}
