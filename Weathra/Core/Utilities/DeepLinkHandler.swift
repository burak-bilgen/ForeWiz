import Foundation
import SwiftUI
import Combine

enum DeepLink: Equatable {
    case home
    case insights
    case settings
    case recommendationDetail(String)
    case paywall
    case onboarding

    static func from(url: URL) -> DeepLink? {
        guard url.scheme == "weathra" else { return nil }

        switch url.host {
        case "home":
            return .home
        case "insights":
            return .insights
        case "settings":
            return .settings
        case "recommendation":
            let id = url.pathComponents.dropFirst().first ?? ""
            return .recommendationDetail(id)
        case "paywall":
            return .paywall
        case "onboarding":
            return .onboarding
        default:
            return nil
        }
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = "weathra"

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
        case .paywall:
            components.host = "paywall"
        case .onboarding:
            components.host = "onboarding"
        }

        return components.url ?? URL(string: "weathra://home")!
    }
}

@MainActor
final class DeepLinkHandler: ObservableObject {
    @Published var pendingLink: DeepLink?

    func handle(_ url: URL) {
        if let link = DeepLink.from(url: url) {
            pendingLink = link
            AnalyticsManager.shared.track(.appLaunch)
        }
    }

    func clear() {
        pendingLink = nil
    }
}