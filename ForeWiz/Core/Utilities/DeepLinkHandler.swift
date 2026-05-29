import Foundation
import SwiftUI

enum DeepLink: Equatable {
    case home
    case insights
    case settings
    case recommendationDetail(String)
    case onboarding

    static func from(url: URL) -> DeepLink? {
        guard url.scheme == "forewiz" else { return nil }

        switch url.host {
        case "home":
            return .home
        case "insights":
            return .insights
        case "settings":
            return .settings
        case "recommendation":
            let id = url.pathComponents.dropFirst().first ?? ""
            let sanitized = id.trimmingCharacters(in: .alphanumerics.inverted)
            guard !sanitized.isEmpty else { return nil }
            return .recommendationDetail(sanitized)
        case "onboarding":
            return .onboarding
        default:
            return nil
        }
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = "forewiz"

        switch self {
        case .home:
            components.host = "home"
        case .insights:
            components.host = "insights"
        case .settings:
            components.host = "settings"
        case .recommendationDetail(let id):
            components.host = "recommendation"
            components.path = "/\(id)"
        case .onboarding:
            components.host = "onboarding"
        }

        return components.url
    }
}

@MainActor
@Observable
final class DeepLinkHandler {
    var pendingLink: DeepLink?

    func handle(_ url: URL) {
        if let link = DeepLink.from(url: url) {
            pendingLink = link
            EventLogger.shared.track(.appLaunch)
        }
    }

    func clear() {
        pendingLink = nil
    }
}
