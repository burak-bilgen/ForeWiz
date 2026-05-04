import SwiftUI

struct NotificationPreferenceToggle: View {
    @Binding var preference: NotificationPreference

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle(preference.category.localizedTitle, isOn: $preference.isEnabled)
            Text(preference.category.localizedDescription)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
