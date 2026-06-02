import Foundation

/// Production-grade retry policy with exponential backoff and jitter.
///
/// Prevents thundering herd problems and gracefully handles transient failures.
/// Based on AWS and Google Cloud best practices.
public struct NetworkRetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let jitterFactor: Double
    
    /// Creates a retry policy with sensible defaults.
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts (default: 3)
    ///   - baseDelay: Initial delay in seconds (default: 0.5)
    ///   - maxDelay: Maximum delay cap in seconds (default: 8.0)
    ///   - jitterFactor: Randomization factor 0-1 (default: 0.25)
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
    
    /// Calculates delay for a specific attempt using exponential backoff with full jitter.
    ///
    /// Formula: delay = min(baseDelay * 2^(attempt-1), maxDelay) * random(1-jitter, 1)
    ///
    /// - Parameter attempt: Attempt number (1-indexed)
    /// - Returns: Delay in seconds
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        
        // Exponential component: baseDelay * 2^(attempt-1)
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
        
        // Cap at maxDelay
        let cappedDelay = min(exponentialDelay, maxDelay)
        
        // Apply jitter to prevent thundering herd
        // Full jitter: random value between (1-jitter) and 1.0
        let jitterRange = 1.0 - jitterFactor ... 1.0
        let jitterMultiplier = Double.random(in: jitterRange)
        
        return cappedDelay * jitterMultiplier
    }
    
    /// All delays for each attempt (useful for testing/debugging).
    public var allDelays: [TimeInterval] {
        (1...maxAttempts).map { delay(forAttempt: $0) }
    }
}

// MARK: - Retryable Errors

public enum RetryableError: Error, Equatable {
    case networkUnavailable
    case timeout
    case serverError(Int) // HTTP status code
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
            return 60 // Default rate limit backoff
        default:
            return nil
        }
    }
}

// MARK: - Retry Executor

public actor RetryExecutor {
    private let policy: NetworkRetryPolicy
    private var attempt = 0
    
    public init(policy: NetworkRetryPolicy = NetworkRetryPolicy()) {
        self.policy = policy
    }
    
    /// Executes an operation with retry logic.
    ///
    /// - Parameters:
    ///   - operation: Async operation to execute
    ///   - shouldRetry: Closure to determine if error is retryable
    /// - Returns: Result of the operation
    /// - Throws: Last error encountered after all retries exhausted
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
                
                // Don't retry on last attempt
                guard attempt < policy.maxAttempts else { break }
                
                // Check if error is retryable
                guard shouldRetry(error) else {
                    throw error
                }
                
                // Calculate and apply delay
                let delay = policy.delay(forAttempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? AppError.unknown
    }
    
    /// Current attempt number (for monitoring/debugging).
    public var currentAttempt: Int {
        attempt
    }
}

// MARK: - Convenience Extensions

extension NetworkRetryPolicy {
    /// Default balanced retry policy for general use.
    public static let `default` = NetworkRetryPolicy(
        maxAttempts: 3,
        baseDelay: 0.5,
        maxDelay: 8.0,
        jitterFactor: 0.25
    )
    
    /// Aggressive retry policy for critical operations.
    public static let aggressive = NetworkRetryPolicy(
        maxAttempts: 5,
        baseDelay: 0.3,
        maxDelay: 16.0,
        jitterFactor: 0.3
    )
    
    /// Conservative retry policy for rate-limited endpoints.
    public static let conservative = NetworkRetryPolicy(
        maxAttempts: 2,
        baseDelay: 2.0,
        maxDelay: 30.0,
        jitterFactor: 0.5
    )
    
    /// No retry - fail fast.
    public static let none = NetworkRetryPolicy(maxAttempts: 1)
}

// MARK: - Integration with Weather Repository

extension WeatherRepository {
    /// Fetches weather with automatic retry using the provided policy.
    func fetchWeather(
        for location: LocationCoordinate,
        retryPolicy: NetworkRetryPolicy
    ) async throws -> WeatherSnapshot {
        let executor = RetryExecutor(policy: retryPolicy)
        
        return try await executor.execute { [self] in
            try await fetchWeather(for: location)
        } shouldRetry: { error in
            // Determine if error is retryable
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
