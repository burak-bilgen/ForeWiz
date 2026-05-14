import Foundation
import Testing
@testable import ForeWiz

struct DeepLinkTests {
    @Test func deepLinkParsingForHome() {
        let url = URL(string: "forewiz://home")!
        let link = DeepLink.from(url: url)

        #expect(link == .home)
    }

    @Test func deepLinkParsingForSettings() {
        let url = URL(string: "forewiz://settings")!
        let link = DeepLink.from(url: url)

        #expect(link == .settings)
    }

    @Test func deepLinkParsingForInsights() {
        let url = URL(string: "forewiz://insights")!
        let link = DeepLink.from(url: url)

        #expect(link == .insights)
    }

    @Test func deepLinkParsingForOnboarding() {
        let url = URL(string: "forewiz://onboarding")!
        let link = DeepLink.from(url: url)

        #expect(link == .onboarding)
    }

    @Test func deepLinkParsingWithRecommendationId() {
        let url = URL(string: "forewiz://recommendation/123")!
        let link = DeepLink.from(url: url)

        #expect(link == .recommendationDetail("123"))
    }

    @Test func invalidSchemeReturnsNil() {
        let url = URL(string: "https://forewiz.app")!
        let link = DeepLink.from(url: url)

        #expect(link == nil)
    }

    @Test func unknownHostReturnsNil() {
        let url = URL(string: "forewiz://unknown")!
        let link = DeepLink.from(url: url)

        #expect(link == nil)
    }

    @Test func deepLinkToURLConversion() {
        let homeLink = DeepLink.home
        #expect(homeLink.url?.scheme == "forewiz")
        #expect(homeLink.url?.host == "home")
    }

    @Test func recommendationDetailURLConversion() {
        let detailLink = DeepLink.recommendationDetail("abc123")
        #expect(detailLink.url?.host == "recommendation")
        #expect(detailLink.url?.pathComponents.contains("abc123") == true)
    }
}
