import SwiftUI

struct ScreenErrorView: View {
    let title: String
    let message: String
    let retryTitle: String
    let retry: () -> Void

    init(title: String = L10n.text("home_loading_error_title"), message: String, retryTitle: String = L10n.text("home_error_retry"), retry: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.retry = retry
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "cloud.slash")
        } description: {
            Text(message)
        } actions: {
            Button(retryTitle, action: retry)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
