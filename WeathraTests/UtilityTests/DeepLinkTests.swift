import Foundation
import Testing
@testable import Weathra

struct DeepLinkTests {
    @Test func deepLinkParsingForHome() {
        let url = URL(string: "weathra://home")!
        let link = DeepLink.from(url: url)

        #expect(link == .home)
    }

    @Test func deepLinkParsingForSettings() {
        let url = URL(string: "weathra://settings")!
        let link = DeepLink.from(url: url)

        #expect(link == .settings)
    }

    @Test func deepLinkParsingForInsights() {
        let url = URL(string: "weathra://insights")!
        let link = DeepLink.from(url: url)

        #expect(link == .insights)
    }

    @Test func deepLinkParsingForPaywall() {
        let url = URL(string: "weathra://paywall")!
        let link = DeepLink.from(url: url)

        #expect(link == .paywall)
    }

    @Test func deepLinkParsingWithRecommendationId() {
        let url = URL(string: "weathra://recommendation/123")!
        let link = DeepLink.from(url: url)

        #expect(link == .recommendationDetail("123"))
    }

    @Test func invalidSchemeReturnsNil() {
        let url = URL(string: "https://weathra.app")!
        let link = DeepLink.from(url: url)

        #expect(link == nil)
    }

    @Test func unknownHostReturnsNil() {
        let url = URL(string: "weathra://unknown")!
        let link = DeepLink.from(url: url)

        #expect(link == nil)
    }

    @Test func deepLinkToURLConversion() {
        let homeLink = DeepLink.home
        #expect(homeLink.url.scheme == "weathra")
        #expect(homeLink.url.host == "home")
    }

    @Test func recommendationDetailURLConversion() {
        let detailLink = DeepLink.recommendationDetail("abc123")
        #expect(detailLink.url.host == "recommendation")
        #expect(detailLink.url.pathComponents.contains("abc123"))
    }
}
