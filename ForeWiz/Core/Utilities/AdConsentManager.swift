import Foundation
import OSLog
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
#if canImport(AdSupport)
import AdSupport
#endif
#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif
import UIKit

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
    private(set) var canRequestAds = false
    private(set) var privacyOptionsRequired = false
    private(set) var lastConsentError: String?
    
    private init() {}
    
    // MARK: - App Tracking Transparency
    
    /// Request ATT permission (required for IDFA access)
    func requestTrackingPermission() async -> ConsentStatus {
        #if canImport(AppTrackingTransparency)
        let status = await ATTrackingManager.requestTrackingAuthorization()
        switch status {
        case .authorized:
            trackingStatus = .granted
            EventLogger.shared.track(.trackingPermissionGranted)
        case .denied, .restricted:
            trackingStatus = .denied
            EventLogger.shared.track(.trackingPermissionDenied)
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

    // MARK: - Google Mobile Ads Consent

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ??
            UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else {
            return nil
        }
        
        guard var topController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }

    /// Refreshes GDPR/EEA consent with Google's User Messaging Platform before any ad request.
    func prepareConsentIfNeeded(presentingViewController: UIViewController? = nil) async {
        #if canImport(UserMessagingPlatform)
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        let requestError = await withCheckedContinuation { (continuation: CheckedContinuation<Error?, Never>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { requestError in
                Task { @MainActor in
                    self.refreshGoogleConsentState()
                    continuation.resume(returning: requestError)
                }
            }
        }

        if let requestError {
            lastConsentError = requestError.localizedDescription
            AppLogger.app.warning("[Consent] UMP consent update failed: \(requestError.localizedDescription)")
            return
        }

        var presenter = presentingViewController
        if presenter == nil {
            presenter = getTopViewController()
        }

        do {
            try await ConsentForm.loadAndPresentIfRequired(from: presenter)
            lastConsentError = nil
        } catch {
            lastConsentError = error.localizedDescription
            AppLogger.app.warning("[Consent] UMP consent form failed: \(error.localizedDescription)")
        }

        refreshGoogleConsentState()
        #else
        gdprConsentGiven = true
        canRequestAds = true
        privacyOptionsRequired = false
        lastConsentError = nil
        #endif
    }

    /// Presents the Google privacy options form from an explicit user action.
    func presentPrivacyOptions(from viewController: UIViewController? = nil) async {
        #if canImport(UserMessagingPlatform)
        var presenter = viewController
        if presenter == nil {
            presenter = getTopViewController()
        }

        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: presenter)
            lastConsentError = nil
        } catch {
            lastConsentError = error.localizedDescription
            AppLogger.app.warning("[Consent] UMP privacy options failed: \(error.localizedDescription)")
        }

        refreshGoogleConsentState()
        #endif
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
    
    /// Check if we can serve personalized ads
    var canServePersonalizedAds: Bool {
        trackingStatus == .granted && canServeAds
    }
    
    /// Check if we can serve ads at all
    var canServeAds: Bool {
        canRequestAds
    }

    private func refreshGoogleConsentState() {
        #if canImport(UserMessagingPlatform)
        let consentInformation = ConsentInformation.shared
        canRequestAds = consentInformation.canRequestAds
        privacyOptionsRequired = consentInformation.privacyOptionsRequirementStatus == .required
        gdprConsentGiven = consentInformation.consentStatus == .obtained ||
            consentInformation.consentStatus == .notRequired
        #else
        gdprConsentGiven = true
        canRequestAds = true
        privacyOptionsRequired = false
        #endif
    }
}
