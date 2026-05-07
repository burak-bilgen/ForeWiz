import CoreLocation
import Foundation

final class CoreLocationRepository: NSObject, LocationRepository {
    private let manager: CLLocationManager
    private var authorizationContinuation: CheckedContinuation<LocationAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<LocationCoordinate, any Error>?

    override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func requestAuthorization() async -> LocationAuthorizationStatus {
        let status = manager.authorizationStatus

        guard status == .notDetermined else {
            return map(status)
        }

        return await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func getCurrentLocation() async throws -> LocationCoordinate {
        let status = manager.authorizationStatus

        if status == .notDetermined {
            let requestedStatus = await requestAuthorization()
            guard requestedStatus == .authorized else {
                throw AppError.locationPermissionDenied
            }
        } else if map(status) != .authorized {
            throw AppError.locationPermissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func map(_ status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            .authorized
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .notDetermined:
            .notDetermined
        @unknown default:
            .restricted
        }
    }
}

extension CoreLocationRepository: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationContinuation?.resume(returning: map(manager.authorizationStatus))
        authorizationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationContinuation?.resume(throwing: AppError.locationUnavailable)
            locationContinuation = nil
            return
        }

        locationContinuation?.resume(returning: LocationCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ))
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        if let clError = error as? CLError, clError.code == .denied {
            locationContinuation?.resume(throwing: AppError.locationPermissionDenied)
        } else {
            locationContinuation?.resume(throwing: AppError.locationUnavailable)
        }
        locationContinuation = nil
    }
}
