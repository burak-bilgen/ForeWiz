import SwiftUI
import Foundation

enum AccessibilityLabels {
    static let temperature = "accessibility_temperature"
    static let humidity = "accessibility_humidity"
    static let wind = "accessibility_wind"
    static let uvIndex = "accessibility_uv_index"
    static let condition = "accessibility_condition"
    static let outdoorScore = "accessibility_outdoor_score"
    static let recommendation = "accessibility_recommendation"
    static let risk = "accessibility_risk"
    static let outfit = "accessibility_outfit"
    static let activity = "accessibility_activity"
    static let forecast = "accessibility_forecast"
    static let refresh = "accessibility_refresh"
    static let settings = "accessibility_settings"
    static let location = "accessibility_location"
    static let premium = "accessibility_premium"
    static let close = "accessibility_close"
    static let back = "accessibility_back"
    static let loading = "accessibility_loading"
    static let error = "accessibility_error"
    static let good = "accessibility_good"
    static let moderate = "accessibility_moderate"
    static let poor = "accessibility_poor"
    static let severe = "accessibility_severe"
    static let button = "accessibility_button"
    static let toggle = "accessibility_toggle"
    static let selected = "accessibility_selected"
    static let unselected = "accessibility_unselected"
    static let hour = "accessibility_hour"
    static let day = "accessibility_day"
    static let currentLocation = "accessibility_current_location"
    static let savedLocation = "accessibility_saved_location"
    static let addLocation = "accessibility_add_location"
    static let delete = "accessibility_delete"
    static let edit = "accessibility_edit"
    static let save = "accessibility_save"
    static let cancel = "accessibility_cancel"
    static let done = "accessibility_done"
    static let next = "accessibility_next"
    static let previous = "accessibility_previous"
    static let step = "accessibility_step"
    static let of = "accessibility_of"
    static let progress = "accessibility_progress"
    static let completed = "accessibility_completed"
    static let pending = "accessibility_pending"
    static let warning = "accessibility_warning"
    static let success = "accessibility_success"
    static let info = "accessibility_info"
}

struct AccessibleModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    let sortPriority: Double
    let hidden: Bool

    init(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        sortPriority: Double = 0,
        hidden: Bool = false
    ) {
        self.label = label
        self.hint = hint
        self.traits = traits
        self.sortPriority = sortPriority
        self.hidden = hidden
    }

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibility(hidden: hidden)
            .applyIfLet(hint) { view, hint in
                view.accessibilityHint(hint)
            }
            .accessibilityAddTraits(traits)
            .accessibilitySortPriority(sortPriority)
    }
}

extension View {
    func accessible(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        sortPriority: Double = 0,
        hidden: Bool = false
    ) -> some View {
        modifier(AccessibleModifier(
            label: label,
            hint: hint,
            traits: traits,
            sortPriority: sortPriority,
            hidden: hidden
        ))
    }

    func accessibleButton(
        label: String,
        hint: String? = nil,
        sortPriority: Double = 0
    ) -> some View {
        modifier(AccessibleModifier(
            label: label,
            hint: hint,
            traits: .isButton,
            sortPriority: sortPriority,
            hidden: false
        ))
    }

    func accessibleHeader(
        label: String,
        sortPriority: Double = 10
    ) -> some View {
        modifier(AccessibleModifier(
            label: label,
            hint: nil,
            traits: .isHeader,
            sortPriority: sortPriority,
            hidden: false
        ))
    }

    func accessibleImage(
        label: String,
        hint: String? = nil,
        sortPriority: Double = 0
    ) -> some View {
        modifier(AccessibleModifier(
            label: label,
            hint: hint,
            traits: .isImage,
            sortPriority: sortPriority,
            hidden: false
        ))
    }

    func accessibleHidden() -> some View {
        modifier(AccessibleModifier(
            label: "",
            hint: nil,
            traits: [],
            sortPriority: 0,
            hidden: true
        ))
    }

    func accessibleValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }

    func accessibleAction(_ action: AccessibilityActionKind, _ handler: @escaping () -> Void) -> some View {
        self.accessibilityAction(action, handler)
    }

    func accessibleAdjustable(_ handler: @escaping (AccessibilityAdjustmentDirection) -> Void) -> some View {
        self.accessibilityAdjustableAction(handler)
    }

    func accessibleAnnouncement(_ text: String, priority: AccessibilityNotification.Priority = .high) {
        AccessibilityNotification.announce(text, priority: priority)
    }

    func reduceMotion() -> Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    func prefersGrayscale() -> Bool {
        UIAccessibility.isGrayscaleEnabled
    }

    func prefersBoldText() -> Bool {
        UIAccessibility.isBoldTextEnabled
    }

    func prefersOnOffSwitchLabels() -> Bool {
        UIAccessibility.isOnOffSwitchLabelsEnabled
    }

    func prefersDifferentiateWithoutColor() -> Bool {
        UIAccessibility.shouldDifferentiateWithoutColor
    }

    func applyIfLet<T, Content: View>(_ value: T?, @ViewBuilder _ transform: (Self, T) -> Content) -> some View {
        if let value = value {
            return AnyView(transform(self, value))
        } else {
            return AnyView(self)
        }
    }
}

enum AccessibilityNotification {
    enum Priority: String {
        case low, high
    }

    static func announce(_ text: String, priority: Priority = .high) {
        if priority == .high {
            UIAccessibility.post(notification: .announcement, argument: text)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .announcement, argument: text)
            }
        }
    }

    static func screenChanged(_ text: String? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: text)
    }

    static func layoutChanged(_ text: String? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: text)
    }

    static func pageScrolled(_ text: String) {
        UIAccessibility.post(notification: .pageScrolled, argument: text)
    }
}

struct AccessibilityPreferences {
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    static var isSwitchControlRunning: Bool {
        UIAccessibility.isSwitchControlRunning
    }

    static var isSpeakScreenEnabled: Bool {
        UIAccessibility.isSpeakScreenEnabled
    }

    static var isSpeakSelectionEnabled: Bool {
        UIAccessibility.isSpeakSelectionEnabled
    }

    static var isMonoAudioEnabled: Bool {
        UIAccessibility.isMonoAudioEnabled
    }

    static var isClosedCaptioningEnabled: Bool {
        UIAccessibility.isClosedCaptioningEnabled
    }

    static var isGuidedAccessEnabled: Bool {
        UIAccessibility.isGuidedAccessEnabled
    }

    static var isAssistiveTouchRunning: Bool {
        UIAccessibility.isAssistiveTouchRunning
    }
}

protocol AccessibleView {
    associatedtype AccessibilityConfiguration
    var accessibilityConfig: AccessibilityConfiguration { get }
    func configureAccessibility() -> AccessibilityConfiguration
}

struct AccessibleCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    let sortPriority: Double

    init(
        title: String,
        icon: String,
        sortPriority: Double = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.sortPriority = sortPriority
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.7)
            }
            .foregroundStyle(Color.white.opacity(0.45))
            .accessibleHeader(label: title, sortPriority: sortPriority)

            content
        }
        .accessible(label: "\(title) card", sortPriority: sortPriority)
    }
}

struct AccessibleButtonStyle: ButtonStyle {
    let accessibilityLabel: String
    let accessibilityHint: String?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .accessibilityLabel(accessibilityLabel)
            .applyIfLet(accessibilityHint) { view, hint in
                view.accessibilityHint(hint)
            }
            .accessibilityAddTraits(.isButton)
    }
}

struct AccessibleToggleStyle: ToggleStyle {
    let accessibilityLabel: String

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Capsule()
                .fill(configuration.isOn ? Color.green : Color.gray)
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if !configuration.isOn { configuration.isOn = true }
            case .decrement:
                if configuration.isOn { configuration.isOn = false }
            @unknown default:
                break
            }
        }
    }
}

extension Text {
    func accessibleTemperature(value: Double, unit: String) -> some View {
        self.accessibilityLabel("Temperature \(Int(value)) degrees \(unit)")
    }

    func accessiblePercentage(value: Double, description: String) -> some View {
        self.accessibilityLabel("\(description): \(Int(value * 100)) percent")
    }

    func accessibleScore(value: Int, outOf: Int = 100, description: String? = nil) -> some View {
        let desc = description ?? "Score"
        let quality: String
        switch value {
        case 80...100: quality = "Excellent"
        case 60..<80: quality = "Good"
        case 40..<60: quality = "Fair"
        case 20..<40: quality = "Poor"
        default: quality = "Very Poor"
        }
        return self.accessibilityLabel("\(desc): \(value) out of \(outOf), \(quality)")
    }

    func accessibleTimeRange(start: Date, end: Date) -> some View {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return self.accessibilityLabel("From \(formatter.string(from: start)) to \(formatter.string(from: end))")
    }

    func accessibleRisk(severity: String, type: String) -> some View {
        self.accessibilityLabel("\(severity) risk: \(type)")
    }
}

struct AccessibleScrollView<Content: View>: View {
    let axis: Axis.Set
    let showsIndicators: Bool
    let content: Content
    let pageSize: CGFloat

    @State private var currentPage: Int = 0

    init(
        axis: Axis.Set = .horizontal,
        showsIndicators: Bool = true,
        pageSize: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.pageSize = pageSize
        self.content = content()
    }

    var body: some View {
        ScrollView(axis, showsIndicators: showsIndicators) {
            content
        }
    }
}

struct AccessibleProgressView: View {
    let progress: Double
    let label: String
    let total: Double

    var body: some View {
        ProgressView(value: progress, total: total)
            .accessibilityLabel(label)
            .accessibilityValue("\(Int((progress / total) * 100)) percent complete")
    }
}

struct AccessibleStepper: View {
    @Binding var value: Int
    let label: String
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            Text(label)
                .accessibilityLabel(label)
                .accessibilityValue("\(value)")
        }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if value + step <= range.upperBound {
                    value += step
                }
            case .decrement:
                if value - step >= range.lowerBound {
                    value -= step
                }
            @unknown default:
                break
            }
        }
    }
}

struct AccessibleSlider: View {
    @Binding var value: Double
    let label: String
    let range: ClosedRange<Double>
    let step: Double?

    var body: some View {
        if let step = step {
            Slider(value: $value, in: range, step: step) {
                Text(label)
            }
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value))")
        } else {
            Slider(value: $value, in: range) {
                Text(label)
            }
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value))")
        }
    }
}

struct AccessibleSegmentedPicker<SelectionValue: Hashable>: View {
    let label: String
    @Binding var selection: SelectionValue
    let options: [SelectionValue]
    let optionLabels: (SelectionValue) -> String

    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(optionLabels(option))
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(label)
        .accessibilityValue(optionLabels(selection))
    }
}

struct AccessibleLoadingView: View {
    let label: String

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .accessibilityLabel(label)
            .accessibilityValue("Loading in progress")
    }
}

struct AccessibleErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)
                .accessibleImage(label: "Error icon")

            Text(title)
                .font(.headline)
                .accessibleHeader(label: title)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .accessible(label: message)

            if let retryAction = retryAction {
                Button("Retry") {
                    retryAction()
                }
                .accessibleButton(label: "Retry", hint: "Attempts to load the content again")
            }
        }
        .padding()
        .accessible(label: "Error message")
    }
}

struct AccessibleEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionLabel: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
                .accessibleImage(label: icon)

            Text(title)
                .font(.headline)
                .accessibleHeader(label: title)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .accessible(label: message)

            if let action = action, let actionLabel = actionLabel {
                Button(actionLabel) {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .accessibleButton(label: actionLabel)
            }
        }
        .padding()
        .accessible(label: "Empty state")
    }
}
