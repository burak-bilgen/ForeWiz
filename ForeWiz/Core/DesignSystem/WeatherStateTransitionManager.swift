import SwiftUI
import Combine

/// Manages smooth, fluid transitions between weather states.
///
/// Creates premium micro-interactions for:
/// - Weather condition changes (sunny → rainy)
/// - Temperature changes (hot → cold)
/// - Time of day transitions (day → night)
/// - Alert state changes (normal → warning)
@MainActor
final class WeatherStateTransitionManager: ObservableObject {
    static let shared = WeatherStateTransitionManager()
    
    @Published private(set) var currentState: WeatherVisualState
    @Published private(set) var transitionProgress: Double = 1.0
    
    private var transitionTask: Task<Void, Never>?
    private let animationDuration: Double
    
    init(animationDuration: Double = 1.5) {
        self.animationDuration = animationDuration
        self.currentState = .default
    }
    
    /// Transitions to a new weather state with smooth animation.
    func transition(to newState: WeatherVisualState) {
        // Cancel any ongoing transition
        transitionTask?.cancel()
        
        // Don't transition to the same state
        guard newState != currentState else { return }
        
        let previousState = currentState
        
        transitionTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Animate progress from 0 to 1
            let startTime = Date()
            
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(elapsed / self.animationDuration, 1.0)
                
                // Use easeInOut curve for smooth transition
                let easedProgress = self.easeInOut(progress)
                
                await MainActor.run {
                    self.transitionProgress = easedProgress
                }
                
                if progress >= 1.0 {
                    break
                }
                
                try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
            }
            
            // Complete transition
            if !Task.isCancelled {
                await MainActor.run {
                    self.currentState = newState
                    self.transitionProgress = 1.0
                }
            }
        }
    }
    
    /// Quickly updates state without animation (for initial load).
    func setStateImmediately(_ state: WeatherVisualState) {
        transitionTask?.cancel()
        currentState = state
        transitionProgress = 1.0
    }
    
    /// Returns interpolated color between two states.
    func interpolatedColor(from start: Color, to end: Color, progress: Double) -> Color {
        // Convert to UIColor for interpolation
        let startUI = UIColor(start)
        let endUI = UIColor(end)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        startUI.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        endUI.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let t = CGFloat(progress)
        return Color(
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t),
            opacity: Double(a1 + (a2 - a1) * t)
        )
    }
    
    private func easeInOut(_ t: Double) -> Double {
        return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    }
}

// MARK: - Weather Visual State

struct WeatherVisualState: Equatable {
    let condition: WeatherCondition
    let timeOfDay: TimeOfDay
    let temperature: TemperatureRange
    let alertLevel: AlertLevel
    
    static let `default` = WeatherVisualState(
        condition: .clear,
        timeOfDay: .day,
        temperature: .moderate,
        alertLevel: .none
    )
    
    init(
        condition: WeatherCondition,
        timeOfDay: TimeOfDay,
        temperature: TemperatureRange,
        alertLevel: AlertLevel
    ) {
        self.condition = condition
        self.timeOfDay = timeOfDay
        self.temperature = temperature
        self.alertLevel = alertLevel
    }
    
    init(from symbolName: String, conditionCode: String?, isDaylight: Bool, hasAlert: Bool) {
        // Parse condition from symbol
        if symbolName.contains("rain") || conditionCode?.contains("rain") == true {
            self.condition = .rainy
        } else if symbolName.contains("snow") || conditionCode?.contains("snow") == true {
            self.condition = .snowy
        } else if symbolName.contains("bolt") || symbolName.contains("storm") || conditionCode?.contains("storm") == true {
            self.condition = .stormy
        } else if symbolName.contains("cloud") || conditionCode?.contains("cloud") == true {
            self.condition = .cloudy
        } else {
            self.condition = .clear
        }
        
        self.timeOfDay = isDaylight ? .day : .night
        self.temperature = .moderate // Would parse from actual temperature
        self.alertLevel = hasAlert ? .warning : .none
    }
}

enum WeatherCondition: String, Equatable {
    case clear, cloudy, rainy, stormy, snowy, foggy
}

enum TimeOfDay: String, Equatable {
    case dawn, day, dusk, night
}

enum TemperatureRange: String, Equatable {
    case freezing, cold, cool, moderate, warm, hot, extreme
}

enum AlertLevel: String, Equatable {
    case none, advisory, warning, emergency
}

// MARK: - SwiftUI View Extension

struct WeatherStateTransitionView<Content: View>: View {
    @StateObject private var transitionManager = WeatherStateTransitionManager.shared
    let content: (WeatherVisualState, Double) -> Content
    
    var body: some View {
        content(transitionManager.currentState, transitionManager.transitionProgress)
    }
}

// MARK: - Animation Modifiers

extension View {
    /// Applies a weather-state-aware transition animation.
    func weatherTransition(
        from oldState: WeatherVisualState,
        to newState: WeatherVisualState,
        progress: Double
    ) -> some View {
        self.modifier(WeatherTransitionModifier(
            oldState: oldState,
            newState: newState,
            progress: progress
        ))
    }
}

struct WeatherTransitionModifier: ViewModifier {
    let oldState: WeatherVisualState
    let newState: WeatherVisualState
    let progress: Double
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .opacity(0.5 + 0.5 * cos(progress * .pi)) // Fade through middle
                .scaleEffect(1.0 + 0.02 * sin(progress * .pi * 2)) // Subtle pulse
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}
