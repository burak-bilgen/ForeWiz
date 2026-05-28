import SwiftUI

// MARK: - Toolbar Language Button

struct ToolbarLanguageButton: View {
    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases, id: \.self) { lang in
                Button {
                    L10n.configure(language: lang)
                    NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
                } label: {
                    if L10n.currentLanguageCode == lang.localeIdentifier {
                        Label(lang.localizedTitle, systemImage: "checkmark")
                    } else {
                        Text(lang.localizedTitle)
                    }
                }
            }

            Divider()

            Button {
                Task {
                    if AdConsentManager.shared.privacyOptionsRequired {
                        await AdConsentManager.shared.presentPrivacyOptions()
                    } else {
                        let privacyURL = L10n.currentLanguageCode == "tr"
                            ? "https://github.com/burak-bilgen/ForeWiz/blob/main/docs/APP_STORE_POLICIES_TR.md"
                            : "https://github.com/burak-bilgen/ForeWiz/blob/main/docs/APP_STORE_POLICIES.md"
                        if let url = URL(string: privacyURL) {
                            _ = await UIApplication.shared.open(url)
                        }
                    }
                }
            } label: {
                Label(L10n.text("settings_privacy_choices"), systemImage: "hand.raised.fill")
            }
        } label: {
            ZStack {
                Image(systemName: "globe")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .accessibilityLabel(L10n.text("settings_language"))
    }
}

// MARK: - Toolbar WizPath Button

struct ToolbarWizPathButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "map.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
        }
        .accessibilityLabel(L10n.text("wizpath_route_planner"))
    }
}
