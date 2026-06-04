import SwiftUI

// MARK: - Warning Banner

struct WarningBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.2))
                    .frame(width: 30, height: 30)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.warning)
            }
            Text(message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.warning.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.warning.opacity(0.2), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.formatted("accessibility_warning_banner_template", message))
    }
}
