import UIKit
import SwiftUI
import Combine

@MainActor
final class HapticEngine: ObservableObject {
    static let shared = HapticEngine()

    private let isAvailable: Bool = {
#if targetEnvironment(simulator)
        return false
#else
        return true
#endif
    }()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private var isPrepared = false

    private init() {}

    func prepare() {
        guard isAvailable, !isPrepared else { return }

        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        softImpact.prepare()
        rigidImpact.prepare()
        notification.prepare()
        selection.prepare()

        isPrepared = true
    }

    func resetPreparation() {
        guard isAvailable else { return }
        isPrepared = false
    }
}

extension HapticEngine {
    func light() {
        guard isAvailable else { return }
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    func medium() {
        guard isAvailable else { return }
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    func heavy() {
        guard isAvailable else { return }
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }

    func soft() {
        guard isAvailable else { return }
        softImpact.impactOccurred()
        softImpact.prepare()
    }

    func rigid() {
        guard isAvailable else { return }
        rigidImpact.impactOccurred()
        rigidImpact.prepare()
    }

    func impact(intensity: Double) {
        guard isAvailable else { return }
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

extension HapticEngine {
    func success() {
        guard isAvailable else { return }
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    func warning() {
        guard isAvailable else { return }
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    func error() {
        guard isAvailable else { return }
        notification.notificationOccurred(.error)
        notification.prepare()
    }
}

extension HapticEngine {
    func selectionChanged() {
        guard isAvailable else { return }
        selection.selectionChanged()
        selection.prepare()
    }
}

extension HapticEngine {

    func weatherRefresh() {
        medium()
    }

    func locationSelected() {
        selectionChanged()
    }

    func dataLoaded() {
        success()
    }

    func weatherAlert() {
        warning()
    }

    func criticalAlert() {
        error()
    }
}

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
