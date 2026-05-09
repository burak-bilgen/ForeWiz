import Foundation
import GoogleMobileAds
import OSLog
import UserMessagingPlatform

enum AdMobConfiguration {
    private static let debugApplicationID = "ca-app-pub-3940256099942544~1458002511"
    private static let debugBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

    static var applicationID: String? {
        let configured = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String
        let trimmed = configured?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        #if DEBUG
        return trimmed.isEmpty ? debugApplicationID : trimmed
        #else
        return trimmed.isEmpty ? nil : trimmed
        #endif
    }

    static var bannerAdUnitID: String? {
        let configured = Bundle.main.object(forInfoDictionaryKey: "GADBannerAdUnitID") as? String
        let trimmed = configured?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        #if DEBUG
        return trimmed.isEmpty ? debugBannerAdUnitID : trimmed
        #else
        return trimmed.isEmpty ? nil : trimmed
        #endif
    }

    static var canLoadAds: Bool {
        applicationID != nil && bannerAdUnitID != nil
    }
}

enum AdsManager {
    @MainActor
    private static var didStartMobileAds = false

    static func configure() {
        guard AdMobConfiguration.canLoadAds else {
            AppLogger.subscription.info("AdMob IDs are not configured; skipping ads startup")
            return
        }

        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
            if let error {
                AppLogger.subscription.error("Consent info update failed: \(error.localizedDescription)")
                startMobileAdsWhenAllowed()
                return
            }

            ConsentForm.loadAndPresentIfRequired(from: nil) { formError in
                if let formError {
                    AppLogger.subscription.error("Consent form failed: \(formError.localizedDescription)")
                }
                startMobileAdsWhenAllowed()
            }
        }
    }

    private static func startMobileAdsWhenAllowed() {
        Task { @MainActor in
            startMobileAdsIfAllowed()
        }
    }

    @MainActor
    private static func startMobileAdsIfAllowed() {
        guard didStartMobileAds == false else { return }
        guard ConsentInformation.shared.canRequestAds else { return }

        didStartMobileAds = true
        MobileAds.shared.start { status in
            let adapters = status.adapterStatusesByClassName.count
            AppLogger.subscription.info("Google Mobile Ads started with \(adapters) adapters")
        }
    }
}
