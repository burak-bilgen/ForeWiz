import Foundation
import GoogleMobileAds
import OSLog
import UserMessagingPlatform

enum AdMobConfiguration {
    private static let debugBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"

    static var bannerAdUnitID: String? {
        #if DEBUG
        return debugBannerAdUnitID
        #else
        guard let id = Bundle.main.object(forInfoDictionaryKey: "GADBannerAdUnitID") as? String,
              id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return nil
        }
        return id
        #endif
    }
}

enum AdsManager {
    @MainActor
    private static var didStartMobileAds = false

    static func configure() {
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

            startMobileAdsWhenAllowed()
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
