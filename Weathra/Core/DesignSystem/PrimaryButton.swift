import SwiftUI

/// The app's primary call-to-action button. Uses a prominent tint, comfortable touch target,
/// and optional medium haptic feedback on tap.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = AppTheme.accent
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var useHaptic: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            if useHaptic {
                HapticManager.medium()
            }
            action()
        } label: {
            HStack(spacing: AppSpacing.small) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(AppTypography.bodyEmphasized)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .controlSize(.large)
        .buttonBorderShape(.roundedRectangle(radius: AppTheme.compactRadius))
        .disabled(isLoading || !isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .animation(AppTheme.smooth, value: isLoading)
    }
}

/// Secondary, less prominent action that complements `PrimaryButton`.
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var useHaptic: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            if useHaptic { HapticManager.medium() }
            action()
        } label: {
            HStack(spacing: AppSpacing.small) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(AppTypography.bodyEmphasized)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .buttonBorderShape(.roundedRectangle(radius: AppTheme.compactRadius))
    }
}
