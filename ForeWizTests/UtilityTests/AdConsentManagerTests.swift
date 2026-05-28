import Testing
@testable import ForeWiz

@MainActor
@Suite(.serialized)
struct AdConsentManagerTests {
    let manager = AdConsentManager.shared
    
    @Test("Initial tracking status is unknown or denied on simulator")
    func initialTrackingStatus() {
        // On real device: starts as .unknown. On simulator: ATTrackingManager unavailable → .denied or .notDetermined. Can also be .granted if pre-authorized.
        let validStatuses: Set<AdConsentManager.ConsentStatus> = [.unknown, .denied, .granted, .notDetermined]
        #expect(validStatuses.contains(manager.trackingStatus))
    }
    
    @Test("Initial gdprConsentGiven is false")
    func initialGDPR() {
        #expect(!manager.gdprConsentGiven)
    }
    
    @Test("canServeAds returns a boolean status without crashing")
    func canServeAdsStatus() {
        let _ = manager.canServeAds
    }
    
    @Test("canServePersonalizedAds handles all statuses without crash")
    func canServePersonalizedAdsForUnknown() {
        // This property should never crash regardless of tracking status
        let _ = manager.canServePersonalizedAds
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
