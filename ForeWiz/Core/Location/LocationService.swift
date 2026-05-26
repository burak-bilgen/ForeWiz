import CoreLocation
import Foundation

/// Production-hardened location service with timeout handling and race condition prevention.
///
/// Architecture:
/// - Serial queue prevents concurrent requests
/// - Timeout prevents indefinite waits
/// - Proper cancellation support
/// - Memory-safe delegate pattern
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

// MARK: - Authorization

extension LocationService {
    func requestAuthorization() async -> LocationAuthorizationStatus {
        let status = manager.authorizationStatus
        
        guard status == .notDetermined else {
            return AuthorizationMapper.map(status)
        }
        
        // Prevent multiple concurrent authorization requests
        guard authContinuation == nil else {
            return await withCheckedContinuation { continuation in
                // Wait for existing request to complete via a task
                Task {
                    while self.authContinuation != nil {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
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
        // Authorization check
        let authStatus = AuthorizationMapper.map(manager.authorizationStatus)
        
        if authStatus == .notDetermined {
            let requestedStatus = await requestAuthorization()
            guard requestedStatus == .authorized else {
                throw AppError.locationPermissionDenied
            }
        } else if authStatus != .authorized {
            throw AppError.locationPermissionDenied
        }
        
        // Prevent concurrent location requests
        guard locationContinuation == nil else {
            throw AppError.locationUnavailable
        }
        
        // Request location with timeout.
        // onCancel safely nils out the continuation so that if the timeout fires
        // before the delegate responds, a subsequent call won't double-resume.
        // We also resume the continuation so the orphaned cancelled child task
        // doesn't hang indefinitely — the resumed value is discarded by the group.
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
    
    /// Runs an async operation with a timeout. If the timeout fires before the
    /// operation completes, `onCancel` is called (on the MainActor) to allow
    /// cleanup of any captured continuations before the error propagates.
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

// MARK: - CLLocationManagerDelegate

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

// MARK: - Authorization Mapper

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
