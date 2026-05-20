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
                    HStack {
                        Text(lang.localizedTitle)
                        if L10n.currentLanguageCode == lang.localeIdentifier {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 40, height: 40)

                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
                    .frame(width: 40, height: 40)

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
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 40, height: 40)

                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
                    .frame(width: 40, height: 40)

                Image(systemName: "map.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .accessibilityLabel(L10n.text("wizpath_route_planner"))
    }
}

