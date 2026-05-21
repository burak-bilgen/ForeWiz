import Foundation
import OSLog
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

// MARK: - Ad Consent Manager
/// Manages user consent for ad tracking (ATT), privacy compliance,
/// and contextual vs personalized ad targeting.
///
/// Handles:
/// - App Tracking Transparency (ATT) prompt
/// - Consent status tracking
/// - GDPR/CCPA compliance flags
/// - Contextual ad mode (no IDFA)
@MainActor
final class AdConsentManager {
    static let shared = AdConsentManager()
    
    // MARK: - Consent Status
    
    enum ConsentStatus: String, Sendable {
        /// User has not been asked yet
        case notDetermined
        /// User denied tracking permission
        case denied
        /// User granted tracking permission
        case authorized
        /// Tracking restricted by system (parental controls, enterprise)
        case restricted
    }
    
    // MARK: - State
    
    private(set) var consentStatus: ConsentStatus = .notDetermined
    private(set) var isContextualMode = true
    private(set) var gdprApplies = false
    private(set) var ccpaOptOut = false
    
    // MARK: - Init
    
    private init() {
        updateConsentStatus()
    }
    
    // MARK: - ATT Request
    
    /// Request App Tracking Transparency permission.
    /// Should be called at a natural moment when user understands the value.
    /// Returns the consent status after the prompt.
    func requestTrackingPermission() async -> ConsentStatus {
        #if canImport(AppTrackingTransparency)
        guard #available(iOS 14.5, *) else {
            return .notDetermined
        }
        
        let status = await ATTrackingManager.requestTrackingAuthorization()
        consentStatus = ConsentMapper.map(status)
        isContextualMode = consentStatus != .authorized
        
        AppLogger.app.info("[Ads] ATT status: \(self.consentStatus.rawValue)")
        AppLogger.app.info("[Ads] Contextual mode: \(self.isContextualMode)")
        
        return consentStatus
        #else
        return .notDetermined
        #endif
    }
    
    /// Check current ATT status without prompting
    func updateConsentStatus() {
        #if canImport(AppTrackingTransparency)
        guard #available(iOS 14.5, *) else {
            consentStatus = .notDetermined
            return
        }
        
        let status = ATTrackingManager.trackingAuthorizationStatus
        consentStatus = ConsentMapper.map(status)
        isContextualMode = consentStatus != .authorized
        #else
        consentStatus = .notDetermined
        #endif
    }
    
    // MARK: - GDPR / CCPA
    
    /// Set GDPR applicability (for EEA users)
    func setGDPRApplies(_ applies: Bool) {
        gdprApplies = applies
        AppLogger.app.info("[Ads] GDPR applies: \(applies)")
    }
    
    /// Set CCPA opt-out status (for California users)
    func setCCPAOptOut(_ optOut: Bool) {
        ccpaOptOut = optOut
        AppLogger.app.info("[Ads] CCPA opt-out: \(optOut)")
    }
    
    // MARK: - Ad Targeting
    
    /// Get ad targeting configuration based on consent
    func adTargetingConfig() -> AdTargetingConfig {
        AdTargetingConfig(
            isPersonalized: consentStatus == .authorized && !ccpaOptOut,
            isContextual: isContextualMode,
            gdprApplies: gdprApplies,
            underAgeOfConsent: false
        )
    }
    
    // MARK: - Debug
    
    func debugInfo() -> String {
        """
        === Ad Consent Debug ===
        Status: \(consentStatus.rawValue)
        Contextual Mode: \(isContextualMode)
        GDPR Applies: \(gdprApplies)
        CCPA Opt-Out: \(ccpaOptOut)
        """
    }
}

// MARK: - Consent Mapper

private enum ConsentMapper {
    #if canImport(AppTrackingTransparency)
    static func map(_ status: ATTrackingManager.AuthorizationStatus) -> AdConsentManager.ConsentStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
    #endif
}

// MARK: - Ad Targeting Config

struct AdTargetingConfig {
    let isPersonalized: Bool
    let isContextual: Bool
    let gdprApplies: Bool
    let underAgeOfConsent: Bool
}
