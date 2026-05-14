import SwiftUI

// MARK: - WizPath HUD Card
/// Home screen entry point for WizPath - Dynamic HUD with terminal aesthetic
struct WizPathHUDCard: View {
    let routeStatus: RouteStatus
    let onTap: () -> Void
    
    @State private var cursorVisible = true
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Route icon
                routeIcon
                
                // Terminal-style text
                HStack(spacing: 0) {
                    Text("> ")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(statusColor)
                    
                    Text(statusText)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(textColor)
                    
                    // Blinking cursor
                    Text(cursorVisible ? "_" : " ")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(statusColor)
                        .opacity(cursorVisible ? 1.0 : 0.0)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#00FF41").opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
        .frame(minHeight: 44)
        .onAppear {
            // Start cursor blink animation
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                cursorVisible.toggle()
            }
        }
    }
    
    // MARK: - Components
    
    private var routeIcon: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 32, height: 32)
            
            Image(systemName: routeStatus.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(statusColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        switch routeStatus {
        case .optimal(let destination, let eta):
            return "SYSTEM: Commute to [ /\(destination.uppercased()) ] is Clear. ETA: \(eta)"
        case .warning(let destination, let hazard, let eta):
            return "WARNING: \(hazard) on Route to [ /\(destination.uppercased()) ]. Tap to Optimize."
        case .critical(let destination, let hazard):
            return "ALERT: \(hazard) - Route to [ /\(destination.uppercased()) ] Compromised."
        case .noRoute:
            return "SYSTEM: No Active Route. Tap to Plan Journey."
        }
    }
    
    private var statusColor: Color {
        switch routeStatus {
        case .optimal:
            return Color(hex: "#00FF41")
        case .warning:
            return Color(hex: "#FF9500")
        case .critical:
            return Color(hex: "#FF3B30")
        case .noRoute:
            return Color(hex: "#00FF41").opacity(0.5)
        }
    }
    
    private var textColor: Color {
        switch routeStatus {
        case .optimal, .noRoute:
            return Color.white.opacity(0.9)
        case .warning, .critical:
            return Color.white
        }
    }
    
    private var borderColor: Color {
        switch routeStatus {
        case .optimal:
            return Color(hex: "#00FF41").opacity(0.4)
        case .warning:
            return Color(hex: "#FF9500").opacity(0.5)
        case .critical:
            return Color(hex: "#FF3B30").opacity(0.6)
        case .noRoute:
            return Color.white.opacity(0.1)
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
            return "checkmark.shield.fill"
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
    VStack(spacing: 20) {
        WizPathHUDCard(
            routeStatus: .optimal(destination: "WORK", eta: "45m"),
            onTap: {}
        )
        
        WizPathHUDCard(
            routeStatus: .warning(destination: "HOME", hazard: "Rain", eta: "55m"),
            onTap: {}
        )
        
        WizPathHUDCard(
            routeStatus: .critical(destination: "WORK", hazard: "Severe Storm"),
            onTap: {}
        )
        
        WizPathHUDCard(
            routeStatus: .noRoute,
            onTap: {}
        )
    }
    .padding()
    .background(Color.black)
}
