import Testing
import Foundation
@testable import ForeWiz

@Test("Double-resume guard: only one callback fires when both are set")
func doubleResumeGuardOnlyOneCallbackFires() async {

    var resumeCount = 0
    let completion: (Bool) -> Void = { _ in resumeCount += 1 }

    var onSingleAdLoaded: ((Bool?) -> Void)? = { _ in completion(true) }
    var onLoadFailed: (() -> Void)? = { completion(false) }

    let singleCompletion = onSingleAdLoaded
    let loadFailedCompletion = onLoadFailed
    onSingleAdLoaded = nil
    onLoadFailed = nil

    if singleCompletion != nil {
        singleCompletion?(nil)
    } else {
        loadFailedCompletion?()
    }

    #expect(resumeCount == 1, "Should resume the continuation exactly once")

    #expect(onSingleAdLoaded == nil)
    #expect(onLoadFailed == nil)
}

@Test("Double-resume guard: subsequent calls are no-ops after first fire")
func doubleResumeGuardSubsequentCallsAreNoOps() {
    var resumeCount = 0
    var onSingleAdLoaded: ((Bool?) -> Void)? = { _ in resumeCount += 1 }
    var onLoadFailed: (() -> Void)? = { resumeCount += 1 }

    let singleCompletion = onSingleAdLoaded
    let _ = onLoadFailed
    onSingleAdLoaded = nil
    onLoadFailed = nil
    singleCompletion?(nil)

    #expect(resumeCount == 1)

    onSingleAdLoaded?(nil)
    onLoadFailed?()

    #expect(resumeCount == 1, "Count should NOT increase after callbacks are nil'd")
}

@Test("Double-resume guard: success path also nils all callbacks")
func doubleResumeGuardSuccessPathNilsAllCallbacks() {
    var onSingleAdLoaded: ((Bool?) -> Void)? = { _ in }
    var onLoadFailed: (() -> Void)? = {}

    if let singleCompletion = onSingleAdLoaded {
        singleCompletion(true)
        onSingleAdLoaded = nil
    } else {

    }

    onSingleAdLoaded = nil
    onLoadFailed = nil

    #expect(onSingleAdLoaded == nil)
    #expect(onLoadFailed == nil)
}

@Test("Stale continuation guard: old continuation is resumed before overwrite")
func staleContinuationGuardOldIsResumedBeforeOverwrite() {
    var oldResumed = false
    var newResumed = false

    var continuation: ((Bool) -> Void)?

    let oldContinuation: (Bool) -> Void = { _ in oldResumed = true }
    continuation = oldContinuation

    if let old = continuation {
        old(false)
    }
    continuation = { _ in newResumed = true }

    #expect(oldResumed, "Old continuation must be resumed")
    #expect(!newResumed, "New continuation should NOT be resumed yet")

    continuation?(true)
    #expect(newResumed, "New continuation should be resumed by delegate")
}

@Test("Timeout cleanup: continuation is resumed and nil'd")
func timeoutCleanupResumesAndNilsContinuation() {
    var resumeCount = 0
    var continuation: ((Bool) -> Void)? = { _ in resumeCount += 1 }

    continuation?(true)
    continuation = nil

    #expect(resumeCount == 1, "Continuation must be resumed exactly once")
    #expect(continuation == nil, "Continuation must be nil'd after timeout")

    guard continuation == nil else {
        #expect(Bool(false), "Retry guard should pass after timeout cleanup")
        return
    }

    continuation = { _ in resumeCount += 1 }
    #expect(continuation != nil, "Fresh continuation should be set for retry")
}

@Test("withTimeout throws on timeout")
func withTimeoutThrowsOnTimeout() async {
    do {
        try await withThrowingTaskGroup(of: String.self) { group in

            group.addTask {
                try await Task.sleep(nanoseconds: 10_000_000_000)
                return "slow"
            }

            group.addTask {
                try await Task.sleep(nanoseconds: 50_000_000)
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

@Test("withTimeout returns result when operation completes in time")
func withTimeoutReturnsResult() async {
    let result = try? await withThrowingTaskGroup(of: String.self) { group in
        group.addTask {
            try await Task.sleep(nanoseconds: 10_000_000)
            throw AppError.locationUnavailable
        }
        group.addTask {
            try await Task.sleep(nanoseconds: 5_000_000)
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

@Test("Deinit cleanup resumes dangling continuations")
func deinitCleanupResumesDanglingContinuations() {

    var resumeValues: [Bool] = []

    var authContinuation: ((Bool) -> Void)? = { resumeValues.append($0) }
    var locationContinuation: ((Bool) -> Void)? = { resumeValues.append($0) }

    authContinuation?(false)
    authContinuation = nil
    locationContinuation?(false)
    locationContinuation = nil

    #expect(resumeValues.count == 2, "Both continuations should be resumed in deinit")
    #expect(authContinuation == nil)
    #expect(locationContinuation == nil)
}

@Test("Deinit cleanup is safe when continuations are already nil")
func deinitCleanupIsSafeWhenNil() {
    var authContinuation: ((Bool) -> Void)?
    var locationContinuation: ((Bool) -> Void)?

    authContinuation?(false)
    authContinuation = nil
    locationContinuation?(false)
    locationContinuation = nil

    #expect(authContinuation == nil)
    #expect(locationContinuation == nil)
}

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

    instance?.closure?()
    #expect(instance?.value == 1)

    instance = nil
    #expect(weakInstance == nil, "Weak self should allow deallocation")
}

@Test("Sendable closures with weak self are safe")
func sendableClosuresWithWeakSelf() async {
    class TestClass: @unchecked Sendable {
        var value = 0
    }

    let obj = TestClass()
    let closure: @Sendable () -> Void = { [weak obj] in
        obj?.value += 1
    }

    await withTaskGroup(of: Void.self) { group in
        group.addTask { closure() }
        group.addTask { closure() }
    }

    #expect(obj.value == 2, "Both closures should execute safely")
}
