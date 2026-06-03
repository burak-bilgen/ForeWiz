import Foundation
import HealthKit

final class HealthKitRepository: HealthRepository {
    private let healthStore = HKHealthStore()
    
    func requestAuthorization() async throws -> Bool {
        preconditionFailure("Not implemented — Task 9")
    }
    
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        preconditionFailure("Not implemented — Task 9")
    }
    
    func readHeartRateSamples(start: Date, end: Date) async throws -> [HealthSample] {
        preconditionFailure("Not implemented — Task 9")
    }
    
    func readSleepSamples(start: Date, end: Date) async throws -> [HealthSample] {
        preconditionFailure("Not implemented — Task 9")
    }
    
    func readStepCount(start: Date, end: Date) async throws -> Double {
        preconditionFailure("Not implemented — Task 9")
    }
    
    func readRespiratoryRate(start: Date, end: Date) async throws -> [HealthSample] {
        preconditionFailure("Not implemented — Task 9")
    }
    
    func readUVExposure(start: Date, end: Date) async throws -> [HealthSample] {
        preconditionFailure("Not implemented — Task 9")
    }
    
    func readRestingHeartRate(start: Date, end: Date) async throws -> Double {
        preconditionFailure("Not implemented — Task 9")
    }
}
