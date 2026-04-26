import SwiftUI

struct NotificationPreferenceToggle: View {
    @Binding var preference: NotificationPreference

    var body: some View {
        Toggle(preference.category.localizedTitle, isOn: $preference.isEnabled)
    }
}
