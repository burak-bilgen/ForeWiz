import SwiftUI

struct ScreenErrorView: View {
    let message: String
    let retryTitle: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(AppTheme.warning)
            Text(message)
                .font(AppTypography.body)
                .multilineTextAlignment(.center)
            Button(retryTitle, action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding(AppSpacing.large)
    }
}
