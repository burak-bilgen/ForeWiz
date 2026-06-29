import Foundation
import OSLog

enum ErrorHandler {
    static func normalized(_ error: any Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        let nsError = error as NSError
        switch nsError.domain {
        case NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .weatherUnavailable
            case NSURLErrorTimedOut:
                return .weatherUnavailable
            default:
                return .weatherUnavailable
            }
        default:
            break
        }

        return .unknown
    }

    static func log(_ error: any Error, context: String = "") {
        let appError = normalized(error)
        let contextText = context.isEmpty ? "" : " - \(context)"
        AppLogger.app.error("\(appError.userMessage)\(contextText)")
    }

    static func handle(_ error: any Error, context: String = "") -> AppError {
        let appError = normalized(error)
        log(error, context: context)
        return appError
    }
}
