import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, LocationRepository {
    private let manager: CLLocationManager
    private let timeout: TimeInterval
    private var authContinuation: CheckedContinuation<LocationAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<LocationCoordinate, any Error>?

    init(timeout: TimeInterval = 8.0) {
        self.manager = CLLocationManager()
        self.timeout = timeout
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 500
    }

    deinit {
        manager.delegate = nil
        locationContinuation?.resume(throwing: AppError.locationUnavailable)
        authContinuation?.resume(returning: .notDetermined)
    }
}

extension LocationService {
    func requestAuthorization() async -> LocationAuthorizationStatus {
        let status = manager.authorizationStatus

        guard status == .notDetermined else {
            return AuthorizationMapper.map(status)
        }

        guard authContinuation == nil else {
            return await withCheckedContinuation { continuation in

                Task {
                    while self.authContinuation != nil {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    continuation.resume(returning: AuthorizationMapper.map(self.manager.authorizationStatus))
                }
            }
        }

        return await withCheckedContinuation { continuation in
            authContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func getCurrentLocation() async throws -> LocationCoordinate {

        let authStatus = AuthorizationMapper.map(manager.authorizationStatus)

        if authStatus == .notDetermined {
            let requestedStatus = await requestAuthorization()
            guard requestedStatus == .authorized else {
                throw AppError.locationPermissionDenied
            }
        } else if authStatus != .authorized {
            throw AppError.locationPermissionDenied
        }

        guard locationContinuation == nil else {
            throw AppError.locationUnavailable
        }

        return try await withTimeout(seconds: timeout, onCancel: { [weak self] in
            guard let self else { return }
            self.locationContinuation?.resume(throwing: AppError.locationUnavailable)
            self.locationContinuation = nil
        }) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<LocationCoordinate, Error>) in
                self.locationContinuation = continuation
                self.manager.requestLocation()
            }
        }
    }

    private func withTimeout<T>(
        seconds: Double,
        onCancel: (@MainActor @Sendable () -> Void)? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AppError.locationUnavailable
            }
            group.addTask {
                try await operation()
            }
            guard let result = try await group.next() else {
                group.cancelAll()
                await MainActor.run { onCancel?() }
                throw AppError.locationUnavailable
            }
            group.cancelAll()
            return result
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = AuthorizationMapper.map(manager.authorizationStatus)
            authContinuation?.resume(returning: status)
            authContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else {
                locationContinuation?.resume(throwing: AppError.locationUnavailable)
                locationContinuation = nil
                return
            }

            let coordinate = LocationCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )

            locationContinuation?.resume(returning: coordinate)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        Task { @MainActor in
            if let clError = error as? CLError, clError.code == .denied {
                locationContinuation?.resume(throwing: AppError.locationPermissionDenied)
            } else {
                locationContinuation?.resume(throwing: AppError.locationUnavailable)
            }
            locationContinuation = nil
        }
    }
}

private enum AuthorizationMapper {
    static func map(_ status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
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
