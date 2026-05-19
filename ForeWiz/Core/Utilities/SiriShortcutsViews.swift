import SwiftUI

// MARK: - Siri Shortcuts Settings View

@available(iOS 16.0, *)
struct SiriShortcutsSettingsView: View {
    @State private var shortcuts: [SiriShortcutInfo] = []

    var body: some View {
        List {
            Section(header: Text(L10n.text("siri_available_shortcuts"))) {
                ForEach(shortcuts) { shortcut in
                    SiriShortcutRow(shortcut: shortcut)
                }
            }

            Section(header: Text(L10n.text("siri_how_to_use"))) {
                Text(L10n.text("siri_how_to_use_desc"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("siri_example_weather"))
                    Text(L10n.text("siri_example_outfit"))
                    Text(L10n.text("siri_example_exercise"))
                    Text(L10n.text("siri_example_risks"))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.text("siri_shortcuts_title"))
        .onAppear {
            loadShortcuts()
        }
    }

    private func loadShortcuts() {
        shortcuts = [
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_weather_rec"),
                description: L10n.text("siri_intent_weather_rec_desc"),
                icon: "cloud.sun.fill",
                phrases: [L10n.text("siri_example_weather"), L10n.text("decision_good")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_temp"),
                description: L10n.text("siri_intent_temp_desc"),
                icon: "thermometer",
                phrases: [L10n.text("siri_intent_temp_title"), L10n.text("weather_current")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_outfit"),
                description: L10n.text("siri_intent_outfit_desc"),
                icon: "tshirt.fill",
                phrases: [L10n.text("siri_example_outfit"), L10n.text("what_to_wear_today")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_exercise"),
                description: L10n.text("siri_intent_exercise_desc"),
                icon: "figure.run",
                phrases: [L10n.text("siri_example_exercise"), L10n.text("notification_best_run")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_risks"),
                description: L10n.text("siri_intent_risks_desc"),
                icon: "exclamationmark.triangle.fill",
                phrases: [L10n.text("siri_example_risks"), L10n.text("alert_warning")]
            ),
            SiriShortcutInfo(
                name: L10n.text("siri_shortcut_refresh"),
                description: L10n.text("siri_intent_refresh_desc"),
                icon: "arrow.clockwise",
                phrases: [L10n.text("refresh_weather"), L10n.text("siri_intent_refresh_title")]
            )
        ]
    }
}

struct SiriShortcutInfo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let phrases: [String]
}

struct SiriShortcutRow: View {
    let shortcut: SiriShortcutInfo

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: shortcut.icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(shortcut.name)
                    .font(.headline)

                Text(shortcut.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(L10n.formatted("siri_try_phrase", shortcut.phrases[0]))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            Spacer()

            Image(systemName: "mic.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 16.0, *)
struct SiriShortcutsButton: View {
    var body: some View {
        NavigationLink(destination: SiriShortcutsSettingsView()) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundStyle(Color.accentColor)

                Text(L10n.text("siri_button_shortcuts"))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
