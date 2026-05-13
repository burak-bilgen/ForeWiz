import SwiftUI

/// A glass-morphic button component with Apple HIG-compliant hit targets.
///
/// Key features:
/// - Guaranteed 44×44pt minimum touch area
/// - Integrated haptic feedback
/// - Glass morphism styling
/// - Accessibility support
struct GlassButton: View {
    let action: () -> Void
    let icon: String
    let label: String?
    let style: ButtonStyle
    let hapticStyle: HapticStyle
    let accessibilityLabel: String
    let accessibilityHint: String?
    
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case danger
        case ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color.white.opacity(0.15)
            case .secondary: return Color.white.opacity(0.10)
            case .tertiary: return Color.white.opacity(0.05)
            case .danger: return Color.red.opacity(0.15)
            case .ghost: return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .tertiary, .ghost:
                return .white
            case .danger:
                return Color(red: 1.0, green: 0.4, blue: 0.4)
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return Color.white.opacity(0.25)
            case .secondary: return Color.white.opacity(0.12)
            case .tertiary: return Color.white.opacity(0.08)
            case .danger: return Color.red.opacity(0.30)
            case .ghost: return Color.clear
            }
        }
    }
    
    enum HapticStyle {
        case light, medium, heavy
        case selection
        case none
        
        @MainActor
        func trigger() {
            switch self {
            case .light: HapticEngine.shared.light()
            case .medium: HapticEngine.shared.medium()
            case .heavy: HapticEngine.shared.heavy()
            case .selection: HapticEngine.shared.selectionChanged()
            case .none: break
            }
        }
    }
    
    init(
        icon: String,
        label: String? = nil,
        style: ButtonStyle = .secondary,
        hapticStyle: HapticStyle = .light,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.style = style
        self.hapticStyle = hapticStyle
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    var body: some View {
        Button {
            hapticStyle.trigger()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                
                if let label = label {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(style.foregroundColor)
            // CRITICAL: Apple HIG 44pt minimum touch target
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, label != nil ? 12 : 0)
        }
        .buttonStyle(GlassButtonStyle(style: style))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "")
    }
}

// MARK: - Button Style

private struct GlassButtonStyle: ButtonStyle {
    let style: GlassButton.ButtonStyle
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(style.borderColor, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Toolbar Button Variants

struct ToolbarLocationButton: View {
    let locationName: String
    let action: () -> Void
    
    var body: some View {
        Button {
            HapticEngine.shared.selectionChanged()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 0.4, green: 0.75, blue: 1.0))
                
                Text(locationName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            // Apple HIG: 44pt minimum
            .frame(minHeight: 44)
            .padding(.horizontal, 8)
        }
        .accessibilityLabel("Choose location")
        .accessibilityHint("Opens location picker to change city")
    }
}

struct ToolbarSettingsButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button {
            HapticEngine.shared.light()
            action()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                // Apple HIG: 44pt minimum touch target
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(isPressed ? 0.15 : 0.0))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .accessibilityLabel("Open settings")
    }
}

// MARK: - Card Action Buttons

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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 18)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.42))
                        .lineLimit(1)
                    
                    Text(detail)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Apple HIG: 44pt minimum
            .frame(minHeight: 44)
            .padding(.horizontal, 10)
        }
        .buttonStyle(CardActionButtonStyle(color: color))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(detail)")
    }
}

private struct CardActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.15 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(color.opacity(configuration.isPressed ? 0.25 : 0.16), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Refresh Button

struct RefreshButton: View {
    let action: () -> Void
    @State private var isSpinning = false
    
    var body: some View {
        Button {
            HapticEngine.shared.weatherRefresh()
            withAnimation(.linear(duration: 1.0)) {
                isSpinning = true
            }
            action()
            
            // Reset animation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isSpinning = false
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.8))
                // Apple HIG: 44pt minimum
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Refresh weather")
        .accessibilityHint("Fetches latest weather data")
    }
}

// MARK: - Press Events Modifier

private struct PressEventsModifier: ViewModifier {
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

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 20) {
            // Primary button
            GlassButton(
                icon: "location.fill",
                label: "Current Location",
                style: .primary,
                accessibilityLabel: "Select location"
            ) {}
            
            // Icon-only button
            GlassButton(
                icon: "gearshape.fill",
                style: .secondary,
                hapticStyle: .medium,
                accessibilityLabel: "Settings"
            ) {}
            
            // Danger button
            GlassButton(
                icon: "exclamationmark.triangle.fill",
                label: "Alert",
                style: .danger,
                hapticStyle: .heavy,
                accessibilityLabel: "Weather alert"
            ) {}
            
            // Ghost button
            GlassButton(
                icon: "info.circle",
                style: .ghost,
                hapticStyle: .selection,
                accessibilityLabel: "Information"
            ) {}
            
            // Card action
            CardActionButton(
                icon: "clock.fill",
                title: "Best Window",
                detail: "14:00 - 16:00",
                color: .green
            ) {}
            
            // Toolbar buttons
            HStack(spacing: 16) {
                ToolbarLocationButton(locationName: "San Francisco") {}
                ToolbarSettingsButton {}
                RefreshButton {}
            }
        }
        .padding()
    }
}
