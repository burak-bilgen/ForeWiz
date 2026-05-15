import SwiftUI

// MARK: - Shared HUD Status
final class WizPathHUDStatus: ObservableObject {
    static let shared = WizPathHUDStatus()
    @Published var currentStatus: RouteStatus = .noRoute
    private init() {}
}

// MARK: - WizPath HUD Card - Liquid Glass Premium
/// Home screen entry point for WizPath with Liquid Glass aesthetic.
/// Features animated glass background, pulse glow, and haptic feedback.
struct WizPathHUDCard: View {
    let routeStatus: RouteStatus
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticEngine.shared.light()
            onTap()
        }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: routeStatus.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(accentColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(statusTitle)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(statusSubtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(accentColor.opacity(0.25), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .contentShape(Rectangle())

        .buttonStyle(.plain)
        .pressEvents(
            onPress: { withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } },
            onRelease: { withAnimation(.easeInOut(duration: 0.1)) { isPressed = false } }
        )
        .frame(minHeight: 48)
    }

    // MARK: - Computed Properties

    private var accentColor: Color {
        switch routeStatus {
        case .optimal: return AppTheme.success
        case .warning: return AppTheme.warning
        case .critical: return AppTheme.danger
        case .noRoute: return AppTheme.liquidAccent
        }
    }

    private var statusTitle: String {
        switch routeStatus {
        case .optimal(let destination, _): return destination
        case .warning(let destination, _, _): return destination
        case .critical(let destination, _): return L10n.formatted("wizpath_alert_format", destination)
        case .noRoute: return L10n.text("wizpath_plan_journey")
        }
    }

    private var statusSubtitle: String {
        switch routeStatus {
        case .optimal(_, let eta): return L10n.formatted("wizpath_clear_route_format", eta)
        case .warning(_, let hazard, let eta): return L10n.formatted("wizpath_hazard_ahead_format", hazard, eta)
        case .critical(_, let hazard): return L10n.formatted("wizpath_hazard_check_format", hazard)
        case .noRoute: return L10n.text("wizpath_tap_destination")
        }
    }
}

// MARK: - Route Status

enum RouteStatus: Equatable {
    case optimal(destination: String, eta: String)
    case warning(destination: String, hazard: String, eta: String)
    case critical(destination: String, hazard: String)
    case noRoute

    var iconName: String {
        switch self {
        case .optimal: return "car.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        case .noRoute: return "mappin.and.ellipse"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppTheme.ambientGradient(for: .dark).ignoresSafeArea()
        VStack(spacing: 16) {
            WizPathHUDCard(routeStatus: .optimal(destination: "Work", eta: "45m"), onTap: {})
            WizPathHUDCard(routeStatus: .warning(destination: "Home", hazard: "Rain", eta: "55m"), onTap: {})
            WizPathHUDCard(routeStatus: .critical(destination: "Work", hazard: "Storm"), onTap: {})
            WizPathHUDCard(routeStatus: .noRoute, onTap: {})
        }
        .padding()
    }
}
