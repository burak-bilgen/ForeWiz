import Foundation
import HealthKit

protocol HealthRepository: AnyObject, Sendable {
    func requestAuthorization() async throws -> Bool
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus
    func readHeartRateSamples(start: Date, end: Date) async throws -> [HealthSample]
    func readSleepSamples(start: Date, end: Date) async throws -> [HealthSample]
    func readStepCount(start: Date, end: Date) async throws -> Double
    func readRespiratoryRate(start: Date, end: Date) async throws -> [HealthSample]
    func readUVExposure(start: Date, end: Date) async throws -> [HealthSample]
    func readRestingHeartRate(start: Date, end: Date) async throws -> Double
}
