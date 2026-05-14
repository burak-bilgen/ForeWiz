import SwiftUI

// MARK: - WizPath HUD Card (Native Apple HIG)
/// Home screen entry point for WizPath - Clean, minimalist iOS design
struct WizPathHUDCard: View {
    let routeStatus: RouteStatus
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Route icon with hierarchical rendering
                routeIcon
                
                // Status text
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(statusSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Chevron with subtle color
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(statusBorderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents(
            onPress: { withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } },
            onRelease: { withAnimation(.easeInOut(duration: 0.1)) { isPressed = false } }
        )
        .frame(minHeight: 44)
    }
    
    // MARK: - Components
    
    private var routeIcon: some View {
        Image(systemName: routeStatus.iconName)
            .font(.system(size: 22, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(statusIconColor)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(statusIconColor.opacity(0.15))
            )
    }
    
    // MARK: - Computed Properties
    
    private var statusTitle: String {
        switch routeStatus {
        case .optimal(let destination, let eta):
            return "Commute to \(destination)"
        case .warning(let destination, let hazard, _):
            return "Commute to \(destination)"
        case .critical(let destination, _):
            return "Alert: \(destination)"
        case .noRoute:
            return "Plan Your Journey"
        }
    }
    
    private var statusSubtitle: String {
        switch routeStatus {
        case .optimal(_, let eta):
            return "Clear conditions • ETA \(eta)"
        case .warning(_, let hazard, let eta):
            return "\(hazard) on route • ETA \(eta)"
        case .critical(_, let hazard):
            return "\(hazard) - Check route"
        case .noRoute:
            return "Tap to set destination"
        }
    }
    
    private var statusIconColor: Color {
        switch routeStatus {
        case .optimal:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        case .noRoute:
            return .blue
        }
    }
    
    private var statusBackgroundColor: Color {
        switch routeStatus {
        case .optimal:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        case .noRoute:
            return .blue
        }
    }
    
    private var statusBorderColor: Color {
        switch routeStatus {
        case .optimal:
            return .green.opacity(0.3)
        case .warning:
            return .orange.opacity(0.3)
        case .critical:
            return .red.opacity(0.3)
        case .noRoute:
            return .blue.opacity(0.3)
        }
    }
}

// MARK: - Route Status Enum
enum RouteStatus: Equatable {
    case optimal(destination: String, eta: String)
    case warning(destination: String, hazard: String, eta: String)
    case critical(destination: String, hazard: String)
    case noRoute
    
    var iconName: String {
        switch self {
        case .optimal:
            return "car.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        case .noRoute:
            return "mappin.and.ellipse"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        WizPathHUDCard(
            routeStatus: .optimal(destination: "Work", eta: "45m"),
            onTap: {}
        )
        
        WizPathHUDCard(
            routeStatus: .warning(destination: "Home", hazard: "Rain", eta: "55m"),
            onTap: {}
        )
        
        WizPathHUDCard(
            routeStatus: .critical(destination: "Work", hazard: "Severe Storm"),
            onTap: {}
        )
        
        WizPathHUDCard(
            routeStatus: .noRoute,
            onTap: {}
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
