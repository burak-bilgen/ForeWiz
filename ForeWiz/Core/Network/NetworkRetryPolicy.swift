import Foundation

public struct NetworkRetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let jitterFactor: Double

    public init(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 0.5,
        maxDelay: TimeInterval = 8.0,
        jitterFactor: Double = 0.25
    ) {
        self.maxAttempts = max(maxAttempts, 1)
        self.baseDelay = max(baseDelay, 0.1)
        self.maxDelay = max(maxDelay, baseDelay)
        self.jitterFactor = max(0, min(jitterFactor, 1))
    }

    public func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }

        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))

        let cappedDelay = min(exponentialDelay, maxDelay)

        let jitterRange = 1.0 - jitterFactor ... 1.0
        let jitterMultiplier = Double.random(in: jitterRange)

        return cappedDelay * jitterMultiplier
    }

    public var allDelays: [TimeInterval] {
        (1...maxAttempts).map { delay(forAttempt: $0) }
    }
}

public enum RetryableError: Error, Equatable {
    case networkUnavailable
    case timeout
    case serverError(Int)
    case rateLimited(retryAfter: TimeInterval?)
    case transient(underlying: String)

    public var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .transient:
            return true
        case .serverError(let code):
            return (500...599).contains(code) || code == 429
        case .rateLimited:
            return true
        }
    }

    public var suggestedDelay: TimeInterval? {
        switch self {
        case .rateLimited(let retryAfter):
            return retryAfter
        case .serverError(429):
            return 60
        default:
            return nil
        }
    }
}

public actor RetryExecutor {
    private let policy: NetworkRetryPolicy
    private var attempt = 0

    public init(policy: NetworkRetryPolicy = NetworkRetryPolicy()) {
        self.policy = policy
    }

    public func execute<T>(
        operation: () async throws -> T,
        shouldRetry: ((any Error)) -> Bool = { _ in true }
    ) async throws -> T {
        var lastError: (any Error)?

        for attempt in 1...policy.maxAttempts {
            self.attempt = attempt

            do {
                return try await operation()
            } catch {
                lastError = error

                guard attempt < policy.maxAttempts else { break }

                guard shouldRetry(error) else {
                    throw error
                }

                let delay = policy.delay(forAttempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError ?? AppError.unknown
    }

    public var currentAttempt: Int {
        attempt
    }
}

extension NetworkRetryPolicy {

    public static let `default` = NetworkRetryPolicy(
        maxAttempts: 3,
        baseDelay: 0.5,
        maxDelay: 8.0,
        jitterFactor: 0.25
    )

    public static let aggressive = NetworkRetryPolicy(
        maxAttempts: 5,
        baseDelay: 0.3,
        maxDelay: 16.0,
        jitterFactor: 0.3
    )

    public static let conservative = NetworkRetryPolicy(
        maxAttempts: 2,
        baseDelay: 2.0,
        maxDelay: 30.0,
        jitterFactor: 0.5
    )

    public static let none = NetworkRetryPolicy(maxAttempts: 1)
}

extension WeatherRepository {

    func fetchWeather(
        for location: LocationCoordinate,
        retryPolicy: NetworkRetryPolicy
    ) async throws -> WeatherSnapshot {
        let executor = RetryExecutor(policy: retryPolicy)

        return try await executor.execute { [self] in
            try await fetchWeather(for: location)
        } shouldRetry: { error in

            if let appError = error as? AppError {
                switch appError {
                case .weatherUnavailable, .weatherKitFailed, .weatherKitPermissionMissing:
                    return true
                default:
                    return false
                }
            }
            return true
        }
    }
}
