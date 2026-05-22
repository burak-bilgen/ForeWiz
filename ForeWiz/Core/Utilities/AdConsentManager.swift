import Foundation
import OSLog
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
#if canImport(AdSupport)
import AdSupport
#endif

// MARK: - Ad Consent Manager
/// Manages user consent for advertising (GDPR, ATT) and ensures
/// compliance with App Store requirements.
@MainActor
final class AdConsentManager {
    static let shared = AdConsentManager()
    
    // MARK: - Consent Status
    
    enum ConsentStatus: String {
        case unknown
        case granted
        case denied
        case notDetermined
    }
    
    // MARK: - State
    
    private(set) var trackingStatus: ConsentStatus = .unknown
    private(set) var gdprConsentGiven = false
    
    private init() {}
    
    // MARK: - App Tracking Transparency
    
    /// Request ATT permission (required for IDFA access)
    func requestTrackingPermission() async -> ConsentStatus {
        #if canImport(AppTrackingTransparency)
        let status = await ATTrackingManager.requestTrackingAuthorization()
        switch status {
        case .authorized:
            trackingStatus = .granted
            AnalyticsManager.shared.track(.trackingPermissionGranted)
        case .denied, .restricted:
            trackingStatus = .denied
            AnalyticsManager.shared.track(.trackingPermissionDenied)
        case .notDetermined:
            trackingStatus = .notDetermined
        @unknown default:
            trackingStatus = .notDetermined
        }
        #else
        trackingStatus = .denied
        #endif
        
        AppLogger.app.info("[Consent] Tracking status: \(self.trackingStatus.rawValue)")
        return trackingStatus
    }
    
    /// Update consent status (call on app launch, before ad requests)
    func updateConsentStatus() {
        #if canImport(AppTrackingTransparency)
        let status = ATTrackingManager.trackingAuthorizationStatus
        switch status {
        case .authorized:
            trackingStatus = .granted
        case .denied, .restricted:
            trackingStatus = .denied
        case .notDetermined:
            trackingStatus = .notDetermined
        @unknown default:
            trackingStatus = .notDetermined
        }
        #else
        trackingStatus = .denied
        #endif
        
        AppLogger.app.info("[Consent] Tracking status updated: \(self.trackingStatus.rawValue)")
    }
    
    // MARK: - System-level ATT Check
    
    /// Check if system-level tracking is disabled in Settings > Privacy & Tracking.
    /// When this is true, `requestTrackingAuthorization()` will silently return `.denied`
    /// without showing the ATT dialog. Users must re-enable it in system Settings.
    var isSystemTrackingDisabled: Bool {
        #if canImport(AppTrackingTransparency)
        return ATTrackingManager.trackingAuthorizationStatus == .denied
        #else
        return true
        #endif
    }
    
    // MARK: - Google Mobile Ads Consent
    
    /// Check if we can serve personalized ads
    var canServePersonalizedAds: Bool {
        trackingStatus == .granted || trackingStatus == .notDetermined
    }
    
    /// Check if we can serve ads at all
    var canServeAds: Bool {
        true // Always serve ads (non-personalized if needed)
    }
}
