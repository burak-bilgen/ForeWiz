import Foundation
import OSLog

// MARK: - Ad Loading Manager
/// Manages ad loading lifecycle with caching, retry logic, and fallback strategies.
@MainActor
final class AdLoadingManager {
    static let shared = AdLoadingManager()
    
    struct Config {
        static let maxRetryAttempts = 3
        static let baseRetryDelay: TimeInterval = 2
        static let cacheExpiry: TimeInterval = 3600
    }
    
    enum LoadState {
        case idle
        case loading(attempt: Int)
        case loaded(cachedAt: Date)
        case failed(attempts: Int)
        case expired
        
        var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
        
        var isLoaded: Bool {
            if case .loaded = self { return true }
            return false
        }
    }
    
    private var loadStates: [AdManager.AdUnit: LoadState] = [:]
    
    private init() {}
    
    func state(for unit: AdManager.AdUnit) -> LoadState {
        guard let state = loadStates[unit] else { return .idle }
        
        if case .loaded(let cachedAt) = state {
            if Date().timeIntervalSince(cachedAt) > Config.cacheExpiry {
                loadStates[unit] = .expired
                return .expired
            }
        }
        
        return state
    }
    
    func isReady(_ unit: AdManager.AdUnit) -> Bool {
        state(for: unit).isLoaded
    }
    
    func markLoading(_ unit: AdManager.AdUnit) {
        loadStates[unit] = .loading(attempt: 1)
    }
    
    func markLoaded(_ unit: AdManager.AdUnit) {
        loadStates[unit] = .loaded(cachedAt: Date())
    }
    
    func markFailed(_ unit: AdManager.AdUnit, attempts: Int = 1) {
        loadStates[unit] = .failed(attempts: attempts)
    }
    
    func clearCache(_ unit: AdManager.AdUnit) {
        loadStates[unit] = nil
    }
    
    func clearAllCaches() {
        loadStates.removeAll()
    }
    
    func debugInfo() -> String {
        var info = "=== Ad Loading Manager ===\n"
        for unit in AdManager.AdUnit.allCases {
            let state = state(for: unit)
            info += "\(unit.rawValue): \(stateDescription(state))\n"
        }
        return info
    }
    
    private func stateDescription(_ state: LoadState) -> String {
        switch state {
        case .idle: return "idle"
        case .loading(let attempt): return "loading (attempt \(attempt))"
        case .loaded(let date):
            let age = Date().timeIntervalSince(date)
            return "loaded (\(Int(age))s ago)"
        case .failed(let attempts): return "failed (\(attempts) attempts)"
        case .expired: return "expired"
        }
    }
}
