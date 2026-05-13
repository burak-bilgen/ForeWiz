import UIKit
import SwiftUI
import Combine

/// A centralized haptic feedback engine using reusable generator instances.
/// 
/// This implementation follows Apple HIG recommendations by:
/// - Reusing feedback generators for better performance
/// - Preparing generators before anticipated interactions
/// - Providing context-appropriate feedback types
@MainActor
final class HapticEngine: ObservableObject {
    static let shared = HapticEngine()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private var isPrepared = false
    
    private init() {}
    
    /// Prepares all generators for upcoming interactions.
    /// Call this before showing interactive UI to minimize latency.
    func prepare() {
        guard !isPrepared else { return }
        
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        softImpact.prepare()
        rigidImpact.prepare()
        notification.prepare()
        selection.prepare()
        
        isPrepared = true
    }
    
    /// Marks generators as needing preparation on next use.
    func resetPreparation() {
        isPrepared = false
    }
}

// MARK: - Impact Feedback

extension HapticEngine {
    func light() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }
    
    func medium() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }
    
    func heavy() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }
    
    func soft() {
        softImpact.impactOccurred()
        softImpact.prepare()
    }
    
    func rigid() {
        rigidImpact.impactOccurred()
        rigidImpact.prepare()
    }
    
    func impact(intensity: Double) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch intensity {
        case 0..<0.2: style = .light
        case 0.2..<0.4: style = .soft
        case 0.4..<0.6: style = .medium
        case 0.6..<0.8: style = .rigid
        default: style = .heavy
        }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: CGFloat(intensity))
    }
}

// MARK: - Notification Feedback

extension HapticEngine {
    func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }
    
    func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }
    
    func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }
}

// MARK: - Selection Feedback

extension HapticEngine {
    func selectionChanged() {
        selection.selectionChanged()
        selection.prepare()
    }
}

// MARK: - Context-Aware Feedback

extension HapticEngine {
    /// Provides feedback appropriate for a weather refresh action.
    func weatherRefresh() {
        medium()
    }
    
    /// Provides feedback when selecting a new location.
    func locationSelected() {
        selectionChanged()
    }
    
    /// Provides feedback for successful data load.
    func dataLoaded() {
        success()
    }
    
    /// Provides feedback when an important weather alert appears.
    func weatherAlert() {
        warning()
    }
    
    /// Provides feedback for critical weather warnings.
    func criticalAlert() {
        error()
    }
}

// MARK: - SwiftUI View Modifier

struct HapticFeedbackModifier: ViewModifier {
    let style: HapticStyle
    @StateObject private var engine = HapticEngine.shared
    
    enum HapticStyle {
        case light, medium, heavy
        case selection
        case success, warning, error
        case weatherRefresh
        case locationSelected
        case dataLoaded
        case weatherAlert
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear { engine.prepare() }
    }
}

// MARK: - Legacy Bridge (for gradual migration)

