import Foundation

// MARK: - Apple PlaceRequest Rate Throttler

/// Apple enforces ~50 place requests per 60 seconds across all place-based APIs
/// (`MKLocalSearch`, `CLGeocoder`, etc.) via `PlaceRequest.REQUEST_TYPE_SEARCH`.
///
/// This throttler ensures we never exceed ~45 requests in any 60‑second sliding window.
/// When the limit is reached, `waitForSlot()` suspends until a slot opens up,
/// then atomically reserves it — so requests are **delayed**, never silently dropped.
///
/// All place‑request callers **must** call `await PlaceRequestThrottler.shared.waitForSlot()`
/// before issuing their request.
public final class PlaceRequestThrottler: @unchecked Sendable {
    public static let shared = PlaceRequestThrottler()

    private let maxRequests = 45
    private let windowSeconds: TimeInterval = 60
    private var timestamps: [Date] = []
    private let lock = NSLock()

    private init() {}

    /// Suspends the current task until a rate‑limit slot is available,
    /// then atomically reserves it.
    public func waitForSlot() async {
        while true {
            let canProceed = lock.withLock { () -> Bool in
                let now = Date()
                timestamps.removeAll { now.timeIntervalSince($0) > windowSeconds }

                guard timestamps.count < maxRequests else {
                    return false
                }

                timestamps.append(now)
                return true
            }

            if canProceed { return }

            // No slot available — wait ~1 s and retry.
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
