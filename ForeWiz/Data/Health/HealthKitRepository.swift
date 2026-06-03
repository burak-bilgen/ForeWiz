import Foundation
import HealthKit

final class HealthKitRepository: HealthRepository {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: .uvExposure)!,
        ]

        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error {
                    let healthError = self.mapError(error)
                    if case .authorizationDenied = healthError {
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(throwing: healthError)
                    }
                    return
                }
                continuation.resume(returning: success)
            }
        }
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .notDetermined
        }
        return healthStore.authorizationStatus(for: type)
    }

    func readHeartRateSamples(start: Date, end: Date) async throws -> [HealthSample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            return []
        }

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: start,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: self.mapError(error))
                    return
                }

                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var samples: [HealthSample] = []
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    guard let averageQuantity = statistics.averageQuantity() else { return }
                    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                    let value = averageQuantity.doubleValue(for: heartRateUnit)
                    let sample = HealthSample(
                        type: .heartRate,
                        value: value,
                        date: statistics.startDate
                    )
                    samples.append(sample)
                }
                continuation.resume(returning: samples)
            }

            self.healthStore.execute(query)
        }
    }

    func readSleepSamples(start: Date, end: Date) async throws -> [HealthSample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            return []
        }

        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: self.mapError(error))
                    return
                }

                guard let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                var totalSleepSeconds: Double = 0
                for sample in categorySamples {
                    guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { continue }
                    switch value {
                    case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        totalSleepSeconds += duration
                    default:
                        break
                    }
                }

                let totalHours = totalSleepSeconds / 3600.0
                let healthSample = HealthSample(
                    type: .sleepHours,
                    value: totalHours,
                    date: start
                )
                continuation.resume(returning: [healthSample])
            }

            self.healthStore.execute(query)
        }
    }

    func readStepCount(start: Date, end: Date) async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            return 0
        }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: self.mapError(error))
                    return
                }

                guard let quantity = statistics?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }

                let value = quantity.doubleValue(for: HKUnit.count())
                continuation.resume(returning: value)
            }

            self.healthStore.execute(query)
        }
    }

    func readRespiratoryRate(start: Date, end: Date) async throws -> [HealthSample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            return []
        }

        let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: respiratoryRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: start,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: self.mapError(error))
                    return
                }

                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var samples: [HealthSample] = []
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    guard let averageQuantity = statistics.averageQuantity() else { return }
                    let respiratoryUnit = HKUnit.count().unitDivided(by: .minute())
                    let value = averageQuantity.doubleValue(for: respiratoryUnit)
                    let sample = HealthSample(
                        type: .respiratoryRate,
                        value: value,
                        date: statistics.startDate
                    )
                    samples.append(sample)
                }
                continuation.resume(returning: samples)
            }

            self.healthStore.execute(query)
        }
    }

    func readUVExposure(start: Date, end: Date) async throws -> [HealthSample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            return []
        }

        let uvExposureType = HKQuantityType.quantityType(forIdentifier: .uvExposure)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: uvExposureType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: start,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: self.mapError(error))
                    return
                }

                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var samples: [HealthSample] = []
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    guard let averageQuantity = statistics.averageQuantity() else { return }
                    let value = averageQuantity.doubleValue(for: HKUnit.count())
                    let sample = HealthSample(
                        type: .uvExposure,
                        value: value,
                        date: statistics.startDate
                    )
                    samples.append(sample)
                }
                continuation.resume(returning: samples)
            }

            self.healthStore.execute(query)
        }
    }

    func readRestingHeartRate(start: Date, end: Date) async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            return 0
        }

        let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: restingHeartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: self.mapError(error))
                    return
                }

                guard let quantity = statistics?.averageQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }

                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                let value = quantity.doubleValue(for: heartRateUnit)
                continuation.resume(returning: value)
            }

            self.healthStore.execute(query)
        }
    }

    // MARK: - Error Mapping

    private func mapError(_ error: Error) -> HealthError {
        guard let hkError = error as? HKError else {
            return .unknown(error)
        }

        switch hkError.code {
        case .errorUserCanceled:
            return .authorizationDenied
        case .errorDatabaseInaccessible:
            return .deviceLocked
        default:
            return .unknown(error)
        }
    }
}
