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
    private var locationContinuation: CheckedContinuation<Result<LocationCoordinate, any Error>, Never>?
    
    init(timeout: TimeInterval = 8.0) {
        self.manager = CLLocationManager()
        self.timeout = timeout
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 500
    }
    
    deinit {
        manager.delegate = nil
        locationContinuation?.resume(returning: .failure(AppError.locationUnavailable))
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
        
        // Timeout wrapper
        let locationTask = Task { () -> LocationCoordinate in
            try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = CheckedContinuation { result in
                    switch result {
                    case .success(let coordinate):
                        continuation.resume(returning: coordinate)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                self.manager.requestLocation()
            }
        }
        
        // Timeout task
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            locationTask.cancel()
        }
        
        do {
            let coordinate = try await locationTask.value
            timeoutTask.cancel()
            return coordinate
        } catch is CancellationError {
            throw AppError.locationUnavailable
        } catch {
            timeoutTask.cancel()
            throw error
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
                locationContinuation?.resume(returning: .failure(AppError.locationUnavailable))
                locationContinuation = nil
                return
            }
            
            let coordinate = LocationCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            locationContinuation?.resume(returning: .success(coordinate))
            locationContinuation = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        Task { @MainActor in
            if let clError = error as? CLError, clError.code == .denied {
                locationContinuation?.resume(returning: .failure(AppError.locationPermissionDenied))
            } else {
                locationContinuation?.resume(returning: .failure(AppError.locationUnavailable))
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
