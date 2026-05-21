import Testing
@testable import ForeWiz

@MainActor
struct AdConsentManagerTests {
    let manager = AdConsentManager.shared
    
    @Test("Initial tracking status is unknown")
    func initialTrackingStatus() {
        #expect(manager.trackingStatus == .unknown)
    }
    
    @Test("Initial gdprConsentGiven is false")
    func initialGDPR() {
        #expect(!manager.gdprConsentGiven)
    }
    
    @Test("canServeAds always returns true")
    func canServeAdsAlwaysTrue() {
        #expect(manager.canServeAds)
    }
    
    @Test("canServePersonalizedAds is true for unknown status")
    func canServePersonalizedAdsForUnknown() {
        // Since we haven't updated, it should be .unknown -> can serve personalized
        #expect(manager.canServePersonalizedAds)
    }
    
    @Test("updateConsentStatus doesn't crash")
    func updateConsentStatus() {
        // Should run without crashing regardless of platform
        manager.updateConsentStatus()
    }
    
    @Test("ConsentStatus enum has all expected cases")
    func consentStatusEnum() {
        #expect(AdConsentManager.ConsentStatus.unknown.rawValue == "unknown")
        #expect(AdConsentManager.ConsentStatus.granted.rawValue == "granted")
        #expect(AdConsentManager.ConsentStatus.denied.rawValue == "denied")
        #expect(AdConsentManager.ConsentStatus.notDetermined.rawValue == "notDetermined")
    }
    
    @Test("requestTrackingPermission doesn't crash")
    func requestTrackingPermission() async {
        // This might behave differently on simulator vs device
        // Just ensure it doesn't crash
        let status = await manager.requestTrackingPermission()
        // Status will be .denied on simulators without ATTrackingManager
    }
}
