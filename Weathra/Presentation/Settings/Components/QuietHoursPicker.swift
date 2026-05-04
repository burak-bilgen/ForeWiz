import SwiftUI

struct QuietHoursPicker: View {
    @Binding var quietHours: TimeWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Toggle("Sessiz saatler", isOn: Binding(
                get: { quietHours != nil },
                set: { enabled in
                    quietHours = enabled ? TimeWindow.previewQuietHours() : nil
                }
            ))

            Text("Sessiz saatler aktifken bu zaman aralığında bildirim gönderilmez.")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)

            if let binding = quietHoursBinding {
                HStack(spacing: AppSpacing.medium) {
                    DatePicker(
                        "Başlangıç",
                        selection: Binding(
                            get: { binding.wrappedValue.start },
                            set: { newStart in
                                binding.wrappedValue = TimeWindow(start: newStart, end: binding.wrappedValue.end, id: "quiet-hours")
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()

                    Text("–")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)

                    DatePicker(
                        "Bitiş",
                        selection: Binding(
                            get: { binding.wrappedValue.end },
                            set: { newEnd in
                                binding.wrappedValue = TimeWindow(start: binding.wrappedValue.start, end: newEnd, id: "quiet-hours")
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
            }
        }
    }

    private var quietHoursBinding: Binding<TimeWindow>? {
        guard quietHours != nil else {
            return nil
        }

        return Binding(
            get: { quietHours ?? TimeWindow.previewQuietHours() },
            set: { quietHours = $0 }
        )
    }
}
