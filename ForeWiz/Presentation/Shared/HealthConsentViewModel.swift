import Foundation
import UIKit
import HealthKit

@MainActor
@Observable
final class HealthConsentViewModel {
    enum FlowState: Equatable {
        case initial
        case loading
        case authorized
        case denied
        case healthKitUnavailable
    }

    private let healthRepository: HealthRepository
    var flowState: FlowState = .initial

    init(healthRepository: HealthRepository) {
        self.healthRepository = healthRepository
    }

    func checkAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            flowState = .healthKitUnavailable
            return
        }

        let heartRateType: HKObjectType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let status = healthRepository.authorizationStatus(for: heartRateType)

        switch status {
        case .sharingAuthorized:
            flowState = .authorized
        case .sharingDenied:
            flowState = .denied
        case .notDetermined:
            flowState = .initial
        @unknown default:
            flowState = .initial
        }
    }

    func requestAuthorization() async {
        flowState = .loading
        do {
            let success = try await healthRepository.requestAuthorization()
            flowState = success ? .authorized : .denied
        } catch {
            flowState = .denied
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
    }
}
