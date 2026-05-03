import SwiftUI

struct PermissionExplainerView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.headline)
                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
