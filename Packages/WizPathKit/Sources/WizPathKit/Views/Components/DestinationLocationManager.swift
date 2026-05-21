import Combine
import CoreLocation
import Foundation

// MARK: - Location Manager

@MainActor
public final class DestinationLocationManager: NSObject, ObservableObject {
    @Published public var userLocation: CLLocation?
    private let manager = CLLocationManager()

    override public init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    public func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        default: break
        }
    }
}

extension DestinationLocationManager: CLLocationManagerDelegate {
    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in self.userLocation = locations.last }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        AppLogger.wizPath.error("Destination picker location error: \(error.localizedDescription)")
    }

    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            Task { @MainActor in
                self.manager.requestLocation()
            }
        }
    }
}
