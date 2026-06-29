import SwiftUI

struct CriticalAlertCard: View {
    let signal: HomeAssistantSignal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.danger.opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: signal.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.danger)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(signal.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.danger)
                    .lineLimit(1)
                Text(signal.subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                if !signal.hint.isEmpty {
                    Text(signal.hint)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
            }
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
    }
}
