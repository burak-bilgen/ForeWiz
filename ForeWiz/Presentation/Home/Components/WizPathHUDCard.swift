import SwiftUI
import WizPathKit

// MARK: - WizPath HUD Card - Liquid Glass Premium
/// Home screen entry point for WizPath with Liquid Glass aesthetic.
/// Features rotating glowing borders, breathing warning overlays, and custom interactive springs.
struct WizPathHUDCard: View {
    let routeStatus: RouteStatus
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var rotationAngle = 0.0
    @State private var pulseScale = 1.0

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
                    
                    // Breathing aura for warnings/alerts
                    if isAlertActive {
                        Circle()
                            .stroke(accentColor.opacity(0.4), lineWidth: 1.5)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - pulseScale)
                    }
                    
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
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
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
            // Premium rotating glass border mapping
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [accentColor.opacity(0.55), .clear, accentColor.opacity(0.55), .clear, accentColor.opacity(0.55)],
                            center: .center,
                            angle: .degrees(rotationAngle)
                        ),
                        lineWidth: 1.2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            )
            // High-fidelity dynamic drop shadows
            .shadow(color: accentColor.opacity(isPressed ? 0.12 : 0.22), radius: isPressed ? 6 : 14, x: 0, y: isPressed ? 3 : 6)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } }
                .onEnded { _ in withAnimation(.easeInOut(duration: 0.15)) { isPressed = false } }
        )
        .frame(minHeight: 48)
        .onAppear {
            // Smooth, low-CPU infinite rotation for border glow
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360.0
            }
            // Breathing animation for hazard warning icons
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.45
            }
        }
    }

    // MARK: - Computed Properties

    private var isAlertActive: Bool {
        switch routeStatus {
        case .warning, .critical: return true
        case .optimal, .noRoute: return false
        }
    }

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

// RouteStatus enum is imported from WizPathKit

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

