import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppTypography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.medium)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
