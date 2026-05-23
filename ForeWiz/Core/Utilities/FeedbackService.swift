import Foundation
import OSLog

// MARK: - Feedback Service
/// Sends user feedback to a Formspree endpoint.
/// No backend required — Formspree forwards submissions to email.
enum FeedbackService {
    // ⚙️ Formspree endpoint — create a free form at https://formspree.io and paste your URL here.
    // The app POSTs JSON to this URL; Formspree forwards it to your email.
    // No backend, no API keys in the binary.
    private static let formspreeEndpoint = "https://formspree.io/f/mnjrznrp"

    enum FeedbackType: String, CaseIterable, Sendable {
        case bugReport
        case featureRequest
        case generalFeedback

        var displayTitle: String {
            switch self {
            case .bugReport: return L10n.text("feedback_type_bug")
            case .featureRequest: return L10n.text("feedback_type_feature")
            case .generalFeedback: return L10n.text("feedback_type_general")
            }
        }
    }

    struct FeedbackPayload: Encodable, Sendable {
        let type: String
        let title: String
        let message: String
        let email: String
        let appVersion: String
        let deviceModel: String
        let systemVersion: String
        let screenshotBase64: String?

        enum CodingKeys: String, CodingKey {
            case type, title, message, email, appVersion, deviceModel, systemVersion
            case screenshotBase64 = "screenshot_base64"
        }
    }

    enum FeedbackError: LocalizedError {
        case invalidEndpoint
        case networkError(Error)
        case invalidResponse(Int)

        var errorDescription: String? {
            switch self {
            case .invalidEndpoint:
                return L10n.text("feedback_error_config")
            case .networkError(let error):
                return "\(L10n.text("error_unknown")) (\(error.localizedDescription))"
            case .invalidResponse(let code):
                return "\(L10n.text("error_unknown")) (HTTP \(code))"
            }
        }
    }

    /// Maximum screenshot size: 10 MB
    private static let maxScreenshotSize = 10 * 1024 * 1024

    /// Sends feedback to Formspree. Returns true on success.
    @discardableResult
    static func sendFeedback(
        type: FeedbackType,
        title: String,
        message: String,
        email: String,
        screenshotData: Data? = nil
    ) async throws -> Bool {
        guard let url = URL(string: formspreeEndpoint) else {
            throw FeedbackError.invalidEndpoint
        }

        // Validate and compress screenshot
        var screenshotBase64: String? = nil
        if let data = screenshotData {
            let imageData: Data
            if data.count > maxScreenshotSize {
                // Image too large — skip sending
                AppLogger.app.warning("[Feedback] Screenshot too large (\(data.count) bytes), skipping attachment")
                imageData = data
            } else {
                imageData = data
            }
            screenshotBase64 = imageData.base64EncodedString()
        }

        let payload = FeedbackPayload(
            type: type.rawValue,
            title: title,
            message: message,
            email: email,
            appVersion: AppInfo.version,
            deviceModel: AppInfo.deviceModel,
            systemVersion: AppInfo.systemVersion,
            screenshotBase64: screenshotBase64
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse(-1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw FeedbackError.invalidResponse(httpResponse.statusCode)
        }

        AppLogger.app.info("[Feedback] Submitted successfully via Formspree")
        return true
    }
}

// MARK: - App Info helpers
enum AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    static var deviceModel: String {
        #if targetEnvironment(simulator)
        "Simulator"
        #else
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
        #endif
    }

    static var systemVersion: String {
        ProcessInfo.processInfo.operatingSystemVersionString
    }
}
