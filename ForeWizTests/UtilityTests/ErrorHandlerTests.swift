import Foundation
import Testing
@testable import ForeWiz

struct ErrorHandlerTests {
    @Test func normalizedAppErrorReturnsSame() {
        let appError = AppError.locationPermissionDenied
        let result = ErrorHandler.normalized(appError)
        #expect(result == appError)
    }

    @Test func normalizedUnknownErrorReturnsUnknown() {
        let unknownError = NSError(domain: "test", code: 999, userInfo: nil)
        let result = ErrorHandler.normalized(unknownError)
        #expect(result == AppError.unknown)
    }

    @Test func normalizedNetworkErrorReturnsWeatherUnavailable() {
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let result = ErrorHandler.normalized(networkError)
        #expect(result == AppError.weatherUnavailable)
    }

    @Test func normalizedTimeoutErrorReturnsWeatherUnavailable() {
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        let result = ErrorHandler.normalized(timeoutError)
        #expect(result == AppError.weatherUnavailable)
    }
}
