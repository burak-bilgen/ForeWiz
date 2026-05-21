import Foundation
import OSLog

// MARK: - Ad Fatigue Prevention
/// Intelligent system to prevent ad fatigue and protect user experience.
/// Distributes ads smartly, respects user engagement patterns, and
/// automatically reduces ad frequency when fatigue is detected.
@MainActor
final class AdFatiguePrevention {
    static let shared = AdFatiguePrevention()
    
    // MARK: - Fatigue Level
    
    enum FatigueLevel: String {
        /// User is engaged, normal ad frequency
        case healthy
        /// User showing mild signs of fatigue, reduce frequency slightly
        case mild
        /// User showing significant fatigue, reduce frequency significantly
        case moderate
        /// User is fatigued, show minimal ads
        case severe
        /// Stop showing ads temporarily
        case critical
        
        var multiplier: Double {
            switch self {
            case .healthy: return 1.0
            case .mild: return 0.75
            case .moderate: return 0.5
            case .severe: return 0.25
            case .critical: return 0.0
            }
        }
        
        var cooldownMultiplier: Double {
            switch self {
            case .healthy: return 1.0
            case .mild: return 1.5
            case .moderate: return 2.0
            case .severe: return 3.0
            case .critical: return 10.0
            }
        }
    }
    
    // MARK: - Configuration
    
    struct Config {
        /// Window for calculating fatigue (minutes)
        static let fatigueWindow: TimeInterval = 30 * 60
        /// Impressions in window to trigger mild fatigue
        static let mildFatigueThreshold = 15
        /// Impressions in window to trigger moderate fatigue
        static let moderateFatigueThreshold = 25
        /// Impressions in window to trigger severe fatigue
        static let severeFatigueThreshold = 35
        /// Impressions in window to trigger critical fatigue
        static let criticalFatigueThreshold = 45
        /// Click-through rate below this indicates fatigue
        static let lowCTRThreshold = 0.01
        /// Dismiss rate above this indicates fatigue
        static let highDismissThreshold = 0.8
        /// Recovery time after critical fatigue (minutes)
        static let criticalRecoveryTime: TimeInterval = 15 * 60
    }
    
    // MARK: - State
    
    private var impressionTimestamps: [Date] = []
    private var clickTimestamps: [Date] = []
    private var dismissTimestamps: [Date] = []
    private var lastCriticalFatigueTime: Date?
    private var currentFatigueLevel: FatigueLevel = .healthy
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Tracking
    
    /// Record an ad impression
    func recordImpression() {
        impressionTimestamps.append(Date())
        cleanupOldTimestamps()
        updateFatigueLevel()
    }
    
    /// Record an ad click
    func recordClick() {
        clickTimestamps.append(Date())
        cleanupOldTimestamps()
        updateFatigueLevel()
    }
    
    /// Record an ad dismiss (user closed ad quickly)
    func recordDismiss() {
        dismissTimestamps.append(Date())
        cleanupOldTimestamps()
        updateFatigueLevel()
    }
    
    // MARK: - Fatigue Calculation
    
    /// Get current fatigue level
    func currentLevel() -> FatigueLevel {
        // Check if we're in critical recovery
        if let lastCritical = lastCriticalFatigueTime {
            let recoveryElapsed = Date().timeIntervalSince(lastCritical)
            if recoveryElapsed < Config.criticalRecoveryTime {
                return .critical
            }
        }
        
        cleanupOldTimestamps()
        updateFatigueLevel()
        return currentFatigueLevel
    }
    
    /// Check if we should show an ad right now
    func shouldShowAd() -> Bool {
        let level = currentLevel()
        return level != .critical
    }
    
    /// Get adjusted interval for next ad based on fatigue
    func adjustedInterval(baseInterval: TimeInterval) -> TimeInterval {
        let level = currentLevel()
        return baseInterval * level.cooldownMultiplier
    }
    
    /// Get adjusted daily limit based on fatigue
    func adjustedDailyLimit(baseLimit: Int) -> Int {
        let level = currentLevel()
        return max(1, Int(Double(baseLimit) * level.multiplier))
    }
    
    // MARK: - Internal
    
    private func cleanupOldTimestamps() {
        let cutoff = Date().addingTimeInterval(-Config.fatigueWindow)
        impressionTimestamps.removeAll { $0 < cutoff }
        clickTimestamps.removeAll { $0 < cutoff }
        dismissTimestamps.removeAll { $0 < cutoff }
    }
    
    private func updateFatigueLevel() {
        let impressionsInWindow = impressionTimestamps.count
        let clicksInWindow = clickTimestamps.count
        let dismissalsInWindow = dismissTimestamps.count
        
        // Calculate CTR
        let ctr = impressionsInWindow > 0 ? Double(clicksInWindow) / Double(impressionsInWindow) : 1.0
        let dismissRate = impressionsInWindow > 0 ? Double(dismissalsInWindow) / Double(impressionsInWindow) : 0.0
        
        // Determine fatigue level
        let newLevel: FatigueLevel
        
        if impressionsInWindow >= Config.criticalFatigueThreshold {
            newLevel = .critical
            if currentFatigueLevel != .critical {
                lastCriticalFatigueTime = Date()
                AppLogger.app.warning("[Fatigue] CRITICAL fatigue detected - pausing ads")
            }
        } else if impressionsInWindow >= Config.severeFatigueThreshold {
            newLevel = .severe
        } else if impressionsInWindow >= Config.moderateFatigueThreshold {
            newLevel = .moderate
        } else if impressionsInWindow >= Config.mildFatigueThreshold {
            newLevel = .mild
        } else if ctr < Config.lowCTRThreshold && impressionsInWindow > 5 {
            // Low engagement indicates fatigue
            newLevel = .moderate
        } else if dismissRate > Config.highDismissThreshold && impressionsInWindow > 3 {
            // High dismiss rate indicates fatigue
            newLevel = .severe
        } else {
            newLevel = .healthy
        }
        
        if newLevel != currentFatigueLevel {
            AppLogger.app.info("[Fatigue] Level changed: \(self.currentFatigueLevel.rawValue) → \(newLevel.rawValue)")
            currentFatigueLevel = newLevel
        }
    }
    
    // MARK: - Reset
    
    /// Reset fatigue tracking (call on new session or manual reset)
    func reset() {
        impressionTimestamps.removeAll()
        clickTimestamps.removeAll()
        dismissTimestamps.removeAll()
        lastCriticalFatigueTime = nil
        currentFatigueLevel = .healthy
        
        AppLogger.app.info("[Fatigue] Reset complete")
    }
    
    // MARK: - Debug
    
    func debugInfo() -> String {
        """
        === Ad Fatigue Debug ===
        Level: \(currentFatigueLevel.rawValue)
        Impressions (30min): \(impressionTimestamps.count)
        Clicks (30min): \(clickTimestamps.count)
        Dismissals (30min): \(dismissTimestamps.count)
        CTR: \(impressionTimestamps.count > 0 ? String(format: "%.2f%%", Double(clickTimestamps.count) / Double(impressionTimestamps.count) * 100) : "N/A")
        Dismiss Rate: \(impressionTimestamps.count > 0 ? String(format: "%.2f%%", Double(dismissTimestamps.count) / Double(impressionTimestamps.count) * 100) : "N/A")
        Multiplier: \(currentFatigueLevel.multiplier)
        Cooldown Multiplier: \(currentFatigueLevel.cooldownMultiplier)
        """
    }
}
