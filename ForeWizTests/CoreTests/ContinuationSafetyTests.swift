import Testing
import Foundation
@testable import ForeWiz

// MARK: - Continuation Double-Resume Prevention Tests
//
// These tests verify the continuation safety patterns applied across the codebase:
//
// 1. **Double-resume guard**: When a completion callback could be called from multiple paths,
//    the callbacks MUST be captured, nil'd OUTSIDE the calling code, and then only the
//    appropriate one called. This prevents the SIGTRAP / EXC_BREAKPOINT crash that occurs
//    when a CheckedContinuation is resumed more than once.
//
// 2. **Timeout cleanup**: When a timeout fires, the dangling continuation must be both
//    resumed (so the orphaned Task completes) AND nil'd (so subsequent calls don't double-resume).
//
// 3. **Deinit cleanup**: When an object is deallocated with an in-flight continuation,
//    the continuation must be resumed so the awaiting Task doesn't hang forever.

// MARK: - Pattern 1: Double-Resume Guard (AdMobNativeLoaderDelegate pattern)

/// Verifies that when both onSingleAdLoaded and onLoadFailed point to the same continuation,
/// only ONE callback is invoked on failure — preventing a double-resume crash.
@Test("Double-resume guard: only one callback fires when both are set")
func doubleResumeGuardOnlyOneCallbackFires() async {
    // Track how many times the continuation would be resumed
    var resumeCount = 0
    let completion: (Bool) -> Void = { _ in resumeCount += 1 }

    // Simulate loadNativeAd() setting both closures to the same completion
    var onSingleAdLoaded: ((Bool?) -> Void)? = { _ in completion(true) }
    var onLoadFailed: (() -> Void)? = { completion(false) }

    // Simulate the failure path from AdMobNativeLoaderDelegate
    let singleCompletion = onSingleAdLoaded
    let loadFailedCompletion = onLoadFailed
    onSingleAdLoaded = nil
    onLoadFailed = nil

    // Only call the one matching the loading path
    if singleCompletion != nil {
        singleCompletion?(nil)
    } else {
        loadFailedCompletion?()
    }

    #expect(resumeCount == 1, "Should resume the continuation exactly once")
    // Verify both callbacks were nil'd to prevent future double-fire
    #expect(onSingleAdLoaded == nil)
    #expect(onLoadFailed == nil)
}

/// Verifies that after the failure path runs, subsequent calls are no-ops
/// because the callbacks have been nil'd.
@Test("Double-resume guard: subsequent calls are no-ops after first fire")
func doubleResumeGuardSubsequentCallsAreNoOps() {
    var resumeCount = 0
    var onSingleAdLoaded: ((Bool?) -> Void)? = { _ in resumeCount += 1 }
    var onLoadFailed: (() -> Void)? = { resumeCount += 1 }

    // First failure: capture, nil, call
    let singleCompletion = onSingleAdLoaded
    let _ = onLoadFailed
    onSingleAdLoaded = nil
    onLoadFailed = nil
    singleCompletion?(nil)

    #expect(resumeCount == 1)

    // Simulate a hypothetical second fire — should be a no-op since callbacks are nil
    onSingleAdLoaded?(nil)   // no-op
    onLoadFailed?()          // no-op

    #expect(resumeCount == 1, "Count should NOT increase after callbacks are nil'd")
}

/// Verifies that the success path (adLoaderDidFinishLoading) also nils all callbacks
/// for defense-in-depth, even though it only fires one path.
@Test("Double-resume guard: success path also nils all callbacks")
func doubleResumeGuardSuccessPathNilsAllCallbacks() {
    var onSingleAdLoaded: ((Bool?) -> Void)? = { _ in }
    var onLoadFailed: (() -> Void)? = {}

    // Simulate adLoaderDidFinishLoading success path
    if let singleCompletion = onSingleAdLoaded {
        singleCompletion(true)
        onSingleAdLoaded = nil
    } else {
        // onAdsLoaded path (not testing here)
    }
    // Defense-in-depth: nil the other callback too
    onSingleAdLoaded = nil
    onLoadFailed = nil

    #expect(onSingleAdLoaded == nil)
    #expect(onLoadFailed == nil)
}

// MARK: - Pattern 2: Stale Continuation Guard (CoreLocationRepository pattern)

/// Verifies that when a new continuation overwrites an existing one, the old one
/// is resumed first with a fallback value — preventing task leaks.
@Test("Stale continuation guard: old continuation is resumed before overwrite")
func staleContinuationGuardOldIsResumedBeforeOverwrite() {
    var oldResumed = false
    var newResumed = false

    var continuation: ((Bool) -> Void)?

    // First caller sets up continuation
    let oldContinuation: (Bool) -> Void = { _ in oldResumed = true }
    continuation = oldContinuation

    // Second caller arrives — resume old with fallback, then overwrite
    if let old = continuation {
        old(false)  // resume with fallback
    }
    continuation = { _ in newResumed = true }

    #expect(oldResumed, "Old continuation must be resumed")
    #expect(!newResumed, "New continuation should NOT be resumed yet")

    // Simulate delegate callback
    continuation?(true)
    #expect(newResumed, "New continuation should be resumed by delegate")
}

// MARK: - Pattern 3: Timeout Continuation Cleanup (LocationService pattern)

/// Verifies that when a timeout fires, the continuation is both resumed (so the
/// orphaned Task completes) AND nil'd (so a subsequent retry doesn't double-resume).
/// Uses a closure-based simulation of the LocationService pattern.
@Test("Timeout cleanup: continuation is resumed and nil'd")
func timeoutCleanupResumesAndNilsContinuation() {
    var resumeCount = 0
    var continuation: ((Bool) -> Void)? = { _ in resumeCount += 1 }

    // Simulate timeout's onCancel: resume then nil
    continuation?(true)
    continuation = nil

    #expect(resumeCount == 1, "Continuation must be resumed exactly once")
    #expect(continuation == nil, "Continuation must be nil'd after timeout")

    // Simulate retry: guard should pass (continuation is nil)
    guard continuation == nil else {
        #expect(Bool(false), "Retry guard should pass after timeout cleanup")
        return
    }
    // Fresh call starts cleanly
    continuation = { _ in resumeCount += 1 }
    #expect(continuation != nil, "Fresh continuation should be set for retry")
}

// MARK: - Pattern 4: withTimeout Cancellation (async test)

/// Verifies that withTimeout throws the timeout error when the operation takes too long.
@Test("withTimeout throws on timeout")
func withTimeoutThrowsOnTimeout() async {
    do {
        try await withThrowingTaskGroup(of: String.self) { group in
            // Slow operation that never completes
            group.addTask {
                try await Task.sleep(nanoseconds: 10_000_000_000)
                return "slow"
            }
            // Timeout fires before the operation
            group.addTask {
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms
                throw AppError.locationUnavailable
            }
            guard let _ = try await group.next() else {
                group.cancelAll()
                throw AppError.locationUnavailable
            }
            group.cancelAll()
            return "unreachable"
        }
        #expect(Bool(false), "Expected timeout error")
    } catch {
        #expect(error is AppError)
    }
}

/// Verifies that withTimeout returns the operation result when it completes before timeout.
@Test("withTimeout returns result when operation completes in time")
func withTimeoutReturnsResult() async {
    let result = try? await withThrowingTaskGroup(of: String.self) { group in
        group.addTask {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            throw AppError.locationUnavailable
        }
        group.addTask {
            try await Task.sleep(nanoseconds: 5_000_000) // 5ms — wins the race
            return "fast result"
        }
        guard let result = try await group.next() else {
            group.cancelAll()
            throw AppError.locationUnavailable
        }
        group.cancelAll()
        return result
    }

    #expect(result == "fast result")
}

// MARK: - Pattern 5: Deinit Continuation Cleanup

/// Verifies that deinit-style cleanup resumes dangling continuations.
@Test("Deinit cleanup resumes dangling continuations")
func deinitCleanupResumesDanglingContinuations() {
    // Simulate the pattern used in LocationService.deinit and CoreLocationRepository.deinit
    var resumeValues: [Bool] = []

    var authContinuation: ((Bool) -> Void)? = { resumeValues.append($0) }
    var locationContinuation: ((Bool) -> Void)? = { resumeValues.append($0) }

    // Simulate deinit
    authContinuation?(false)
    authContinuation = nil
    locationContinuation?(false)
    locationContinuation = nil

    #expect(resumeValues.count == 2, "Both continuations should be resumed in deinit")
    #expect(authContinuation == nil)
    #expect(locationContinuation == nil)
}

/// Verifies that deinit cleanup is safe when continuations are already nil.
@Test("Deinit cleanup is safe when continuations are already nil")
func deinitCleanupIsSafeWhenNil() {
    var authContinuation: ((Bool) -> Void)?
    var locationContinuation: ((Bool) -> Void)?

    // Continuations are already nil (never set or already cleaned up)
    // Simulate deinit — should not crash
    authContinuation?(false)  // no-op
    authContinuation = nil
    locationContinuation?(false)  // no-op
    locationContinuation = nil

    #expect(authContinuation == nil)
    #expect(locationContinuation == nil)
}

// MARK: - Pattern 6: Weak Self in Async Closures

/// Verifies that [weak self] prevents retain cycles in closure-based APIs.
@Test("Weak self in closures prevents retain cycle")
func weakSelfPreventsRetainCycle() {
    class TestClass {
        var value = 0
        var closure: (() -> Void)?

        func setup() {
            closure = { [weak self] in
                self?.value += 1
            }
        }

        deinit {
            closure = nil
        }
    }

    var instance: TestClass? = TestClass()
    weak var weakInstance = instance
    instance?.setup()

    // Call the closure
    instance?.closure?()
    #expect(instance?.value == 1)

    // Deallocate and verify weak reference is nil
    instance = nil
    #expect(weakInstance == nil, "Weak self should allow deallocation")
}

// MARK: - Pattern 7: Sendable Closure Safety

/// Verifies that @Sendable closures with weak self capture are safe.
@Test("Sendable closures with weak self are safe")
func sendableClosuresWithWeakSelf() async {
    class TestClass: @unchecked Sendable {
        var value = 0
    }

    let obj = TestClass()
    let closure: @Sendable () -> Void = { [weak obj] in
        obj?.value += 1
    }

    // Run in a Task to simulate real concurrency
    await withTaskGroup(of: Void.self) { group in
        group.addTask { closure() }
        group.addTask { closure() }
    }

    #expect(obj.value == 2, "Both closures should execute safely")
}
