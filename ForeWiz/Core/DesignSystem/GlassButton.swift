import SwiftUI

// MARK: - Liquid Glass Button
/// Premium liquid glass button with animated sheen, haptics, and adaptive accents.
///
/// Features:
/// - 44pt minimum hit target (Apple HIG)
/// - Animated glass sheen on primary buttons
/// - Premium spring press animations
/// - Integrated haptic feedback
/// - Full accessibility support
struct LiquidGlassButton: View {
    let title: String?
    let icon: String?
    let style: LiquidGlassButtonStyle
    let haptic: LiquidHapticStyle
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    enum LiquidGlassButtonStyle {
        case primary  // Filled glass with glow
        case secondary // Bordered glass
        case tertiary  // Subtle glass
        case danger    // Red-tinted glass

        var accentColor: Color {
            switch self {
            case .primary: return AppTheme.liquidAccent
            case .secondary: return AppTheme.liquidAccentSoft
            case .tertiary: return .white.opacity(0.6)
            case .danger: return AppTheme.coral
            }
        }

        var backgroundOpacity: Double {
            switch self {
            case .primary: return 0.20
            case .secondary: return 0.10
            case .tertiary: return 0.04
            case .danger: return 0.18
            }
        }

        var hasSheen: Bool {
            switch self {
            case .primary: return true
            default: return false
            }
        }
    }

    enum LiquidHapticStyle {
        case light, medium, heavy, selection, success, none

        @MainActor
        func trigger() {
            switch self {
            case .light: HapticEngine.shared.light()
            case .medium: HapticEngine.shared.medium()
            case .heavy: HapticEngine.shared.heavy()
            case .selection: HapticEngine.shared.selectionChanged()
            case .success: HapticEngine.shared.success()
            case .none: break
            }
        }
    }

    init(
        _ title: String? = nil,
        icon: String? = nil,
        style: LiquidGlassButtonStyle = .secondary,
        haptic: LiquidHapticStyle = .light,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.haptic = haptic
        self.action = action
    }

    var body: some View {
        Button {
            if isEnabled {
                haptic.trigger()
                action()
            }
        } label: {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(style.accentColor)
                }
                if let title = title {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            style == .tertiary
                                ? .white.opacity(0.65)
                                : .white
                        )
                }
            }
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, title != nil ? 18 : 14)
            .padding(.vertical, 12)
            .background(glassBackground)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.4)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    if !reduceMotion {
                        HapticEngine.shared.selectionChanged()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isPressed)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)

            // Tinted overlay
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(style.accentColor.opacity(style.backgroundOpacity))

            // Top highlight
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.18),
                            style.accentColor.opacity(0.08),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )

            // Sheen (primary only)
            if style.hasSheen && !reduceMotion {
                LiquidButtonSheen(accent: style.accentColor)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var accessibilityLabel: String {
        [title, icon].compactMap { $0 }.joined(separator: ", ")
    }
}

// MARK: - Button Sheen Animation

private struct LiquidButtonSheen: View {
    let accent: Color
    @State private var offset: CGFloat = -1.0

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    .clear,
                    accent.opacity(0.12),
                    .white.opacity(0.06),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.6)
            .offset(x: offset * (geo.size.width + geo.size.width * 0.6))
            .blendMode(.plusLighter)
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false).delay(0.5)) {
                    offset = 1.0
                }
            }
        }
        .clipped()
    }
}

// MARK: - Compact Icon Button

struct IconGlassButton: View {
    let icon: String
    let style: LiquidGlassButton.LiquidGlassButtonStyle
    let action: () -> Void

    var body: some View {
        LiquidGlassButton(
            icon: icon,
            style: style,
            haptic: .selection,
            action: action
        )
    }
}

// MARK: - Toolbar Buttons

struct ToolbarLocationButton: View {
    let locationName: String
    let action: () -> Void

    var body: some View {
        Button {
            HapticEngine.shared.selectionChanged()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.liquidAccent)
                Text(locationName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text("current_location"))
        .accessibilityHint(L10n.text("tap_to_change_location"))
    }
}

struct ToolbarSettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            HapticEngine.shared.light()
            action()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.06), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text("settings_title"))
    }
}

struct ToolbarRefreshButton: View {
    let action: () -> Void
    @State private var isSpinning = false

    var body: some View {
        Button {
            HapticEngine.shared.weatherRefresh()
            action()
            withAnimation(.linear(duration: 0.8)) {
                isSpinning = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isSpinning = false
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.06), lineWidth: 0.5)
                )
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
        }
        .buttonStyle(.plain)
        .animation(.linear(duration: 0.8), value: isSpinning)
        .accessibilityLabel(L10n.text("refresh_weather"))
    }
}

// MARK: - Card Action Button

struct CardActionButton: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            HapticEngine.shared.medium()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                    Text(detail)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(detail)")
    }
}

// MARK: - Legacy GlassButton

@available(*, deprecated, message: "Use LiquidGlassButton instead")
struct GlassButton: View {
    let action: () -> Void
    let icon: String
    let label: String?
    let style: GlassButton.Style
    let hapticStyle: GlassButton.HapticStyle

    enum Style { case primary, secondary, tertiary, danger, ghost }
    enum HapticStyle { case light, medium, heavy, selection, none }

    init(
        icon: String,
        label: String? = nil,
        style: Style = .secondary,
        hapticStyle: HapticStyle = .light,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.style = style
        self.hapticStyle = hapticStyle
        self.action = action
    }

    var body: some View {
        LiquidGlassButton(
            label,
            icon: icon,
            style: style.liquidStyle,
            haptic: hapticStyle.liquidHaptic,
            action: action
        )
    }
}

private extension GlassButton.Style {
    var liquidStyle: LiquidGlassButton.LiquidGlassButtonStyle {
        switch self {
        case .primary: return .primary
        case .secondary: return .secondary
        case .tertiary: return .tertiary
        case .danger: return .danger
        case .ghost: return .tertiary
        }
    }
}

private extension GlassButton.HapticStyle {
    var liquidHaptic: LiquidGlassButton.LiquidHapticStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        case .selection: return .selection
        case .none: return .none
        }
    }
}

// MARK: - Press Events (Legacy Support)

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppTheme.ambientGradient(for: .dark)
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                LiquidGlassButton("Get Started", icon: "sparkles", style: .primary, haptic: .medium) {}
                LiquidGlassButton("Search", icon: "magnifyingglass", style: .secondary) {}
                LiquidGlassButton("Info", icon: "info.circle", style: .tertiary) {}
                LiquidGlassButton("Delete", icon: "trash.fill", style: .danger, haptic: .heavy) {}

                HStack(spacing: 12) {
                    ToolbarLocationButton(locationName: "San Francisco") {}
                    ToolbarSettingsButton {}
                    ToolbarRefreshButton {}
                }

                CardActionButton(
                    icon: "clock.fill",
                    title: "Best Time",
                    detail: "14:00 - 16:00",
                    color: .green
                ) {}
            }
            .padding()
        }
    }
}
