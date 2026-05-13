import SwiftUI

/// Critical weather alert banner with high-visibility styling.
struct CriticalAlertView: View {
    let signal: HomeAssistantSignal
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            iconContainer
            alertContent
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.danger.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.danger.opacity(0.25), lineWidth: 1)
        )
        // Apple HIG: 44pt minimum touch target
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Critical Alert: \(signal.title). \(signal.subtitle)")
        .accessibilityPriority(.high)
    }
    
    private var iconContainer: some View {
        ZStack {
            Circle()
                .fill(AppTheme.danger.opacity(0.18))
                .frame(width: 40, height: 40)
            
            Image(systemName: signal.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.danger)
        }
    }
    
    private var alertContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(signal.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.danger)
            
            Text(signal.subtitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(3)
            
            if !signal.hint.isEmpty {
                Text(signal.hint)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Warning Banner

struct WarningBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            icon
            messageText
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 1.0, green: 0.65, blue: 0.2).opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 1.0, green: 0.55, blue: 0.15).opacity(0.2), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: \(message)")
    }
    
    private var icon: some View {
        ZStack {
            Circle()
                .fill(Color(red: 1.0, green: 0.65, blue: 0.2).opacity(0.2))
                .frame(width: 32, height: 32)
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.2))
        }
    }
    
    private var messageText: some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 16) {
            CriticalAlertView(signal: HomeAssistantSignal(
                id: "test",
                icon: "exclamationmark.triangle.fill",
                title: "Severe Weather Alert",
                subtitle: "Thunderstorm warning in effect until 6:00 PM",
                hint: "San Francisco Bay Area - NWS",
                tone: .danger
            ))
            
            WarningBanner(message: "Using cached weather data. Last updated 2 hours ago.")
        }
        .padding()
    }
}
