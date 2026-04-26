import SwiftUI

struct QuietHoursPicker: View {
    @Binding var quietHours: TimeWindow?

    var body: some View {
        Toggle("Sessiz saatler", isOn: Binding(
            get: { quietHours != nil },
            set: { enabled in
                quietHours = enabled ? TimeWindow.previewQuietHours() : nil
            }
        ))
    }
}
