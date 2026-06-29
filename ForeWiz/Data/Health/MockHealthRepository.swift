import Foundation
import HealthKit

final class MockHealthRepository: HealthRepository, @unchecked Sendable {
    var mockHeartRateSamples: [HealthSample] = []
    var mockSleepSamples: [HealthSample] = []
    var mockStepCount: Double = 0
    var mockRespiratoryRateSamples: [HealthSample] = []
    var mockUVExposureSamples: [HealthSample] = []
    var mockRestingHeartRate: Double = 0
    var mockAuthorizationResult: Bool = true

    func requestAuthorization() async throws -> Bool { mockAuthorizationResult }
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus { .sharingAuthorized }
    func readHeartRateSamples(start: Date, end: Date) async throws -> [HealthSample] { mockHeartRateSamples }
    func readSleepSamples(start: Date, end: Date) async throws -> [HealthSample] { mockSleepSamples }
    func readStepCount(start: Date, end: Date) async throws -> Double { mockStepCount }
    func readRespiratoryRate(start: Date, end: Date) async throws -> [HealthSample] { mockRespiratoryRateSamples }
    func readUVExposure(start: Date, end: Date) async throws -> [HealthSample] { mockUVExposureSamples }
    func readRestingHeartRate(start: Date, end: Date) async throws -> Double { mockRestingHeartRate }
}
