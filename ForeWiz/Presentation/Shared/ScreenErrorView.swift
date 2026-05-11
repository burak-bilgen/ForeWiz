import SwiftUI

/// Empty/error state using the native `ContentUnavailableView`. Adapts to light/dark
/// automatically and offers a clear retry action.
struct ScreenErrorView: View {
    let message: String
    let retryTitle: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(L10n.text("home_loading_error_title"), systemImage: "cloud.slash")
        } description: {
            Text(message)
        } actions: {
            Button(retryTitle, action: retry)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
