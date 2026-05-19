import SwiftUI

/// Centralized micro-interaction system for premium tactile feedback.
///
/// Provides consistent, delightful interactions across the app:
/// - Button press states with spring animations
/// - Card entrance/exit animations
/// - Pull-to-refresh feedback
/// - Success/error state transitions
@MainActor
final class MicroInteractionManager {
    static let shared = MicroInteractionManager()
    
    private init() {}
    
    // MARK: - Button Interactions
    
    /// Applies premium button press animation.
    func buttonPressAnimation(isPressed: Bool) -> Animation {
        isPressed
            ? .spring(response: 0.2, dampingFraction: 0.7)
            : .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    /// Scale effect for button press.
    func buttonPressScale(isPressed: Bool) -> CGFloat {
        isPressed ? 0.94 : 1.0
    }
    
    /// Opacity effect for button press.
    func buttonPressOpacity(isPressed: Bool) -> Double {
        isPressed ? 0.8 : 1.0
    }
    
    // MARK: - Card Interactions
    
    /// Entrance animation for cards with staggered delay.
    func cardEntranceAnimation(index: Int, baseDelay: Double = 0.0) -> Animation {
        AppTheme.cardSpring
        .delay(baseDelay + Double(index) * AppTheme.staggerDelay)
    }
    
    /// Initial offset for card entrance.
    func cardEntranceOffset(isVisible: Bool) -> CGFloat {
        isVisible ? 0 : 20
    }
    
    /// Scale for card entrance.
    func cardEntranceScale(isVisible: Bool) -> CGFloat {
        isVisible ? 1.0 : 0.95
    }
    
    // MARK: - Weather Refresh
    
    /// Rotation angle for refresh button.
    func refreshRotation(isRefreshing: Bool) -> Double {
        isRefreshing ? 360 : 0
    }
    
    /// Duration for refresh animation.
    var refreshDuration: Double { 1.0 }
    
    /// Animation curve for refresh.
    var refreshAnimation: Animation {
        .linear(duration: refreshDuration)
        .repeatForever(autoreverses: false)
    }
    
    // MARK: - State Change
    
    /// Duration for state change transitions.
    var stateChangeDuration: Double { 0.4 }
    
    /// Animation for state changes.
    var stateChangeAnimation: Animation {
        AppTheme.transitionSpring
    }
    
    // MARK: - Haptic Integration
    
    /// Triggers appropriate haptic for weather state change.
    func triggerStateChangeHaptic(from oldState: WeatherVisualState, to newState: WeatherVisualState) {
        // Major condition changes
        if oldState.condition != newState.condition {
            HapticEngine.shared.medium()
        }
        
        // Alert level changes
        if oldState.alertLevel != newState.alertLevel {
            switch newState.alertLevel {
            case .none:
                HapticEngine.shared.success()
            case .advisory:
                HapticEngine.shared.selectionChanged()
            case .warning:
                HapticEngine.shared.warning()
            case .emergency:
                HapticEngine.shared.criticalAlert()
            }
        }
    }
    
    /// Triggers haptic for successful data load.
    func triggerDataLoadedHaptic() {
        HapticEngine.shared.dataLoaded()
    }
    
    /// Triggers haptic for error state.
    func triggerErrorHaptic() {
        HapticEngine.shared.error()
    }
}

// MARK: - View Modifiers

struct MicroButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(MicroInteractionManager.shared.buttonPressScale(isPressed: configuration.isPressed))
            .opacity(MicroInteractionManager.shared.buttonPressOpacity(isPressed: configuration.isPressed))
            .animation(
                reduceMotion ? .none : MicroInteractionManager.shared.buttonPressAnimation(isPressed: configuration.isPressed),
                value: configuration.isPressed
            )
    }
}

struct MicroCardEntranceModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .offset(y: MicroInteractionManager.shared.cardEntranceOffset(isVisible: isVisible))
            .scaleEffect(MicroInteractionManager.shared.cardEntranceScale(isVisible: isVisible))
            .opacity(isVisible ? 1 : 0)
            .animation(
                reduceMotion ? .easeOut(duration: 0.2) : MicroInteractionManager.shared.cardEntranceAnimation(index: index, baseDelay: baseDelay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

struct MicroRefreshModifier: ViewModifier {
    let isRefreshing: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(MicroInteractionManager.shared.refreshRotation(isRefreshing: isRefreshing)))
            .animation(
                reduceMotion ? .none : (isRefreshing ? MicroInteractionManager.shared.refreshAnimation : .default),
                value: isRefreshing
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies premium button micro-interactions.
    func microButton() -> some View {
        buttonStyle(MicroButtonStyle())
    }
    
    /// Applies card entrance animation with staggered delay.
    func microCardEntrance(index: Int, baseDelay: Double = 0.0) -> some View {
        modifier(MicroCardEntranceModifier(index: index, baseDelay: baseDelay))
    }
    
    /// Applies refresh rotation animation.
    func microRefresh(isRefreshing: Bool) -> some View {
        modifier(MicroRefreshModifier(isRefreshing: isRefreshing))
    }
}

