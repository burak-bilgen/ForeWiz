import SwiftUI
import WizPathKit

// MARK: - Compact Icon Button

struct IconGlassButton: View {
    let icon: String
    let style: LiquidGlassButtonStyle
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
                    .foregroundStyle(Color.liquidAccent)
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
        }
        .contentShape(Rectangle())
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
        .contentShape(Rectangle())
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
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .animation(.linear(duration: 0.8), value: isSpinning)
        .accessibilityLabel(L10n.text("btn_refresh_weather"))
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
                        .minimumScaleFactor(0.85)
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
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.formatted("%@: %@", title, detail))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                ToolbarLocationButton(locationName: "San Francisco") {}
                ToolbarSettingsButton {}
                ToolbarRefreshButton {}
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
