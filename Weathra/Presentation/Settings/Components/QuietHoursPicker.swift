import SwiftUI

struct QuietHoursPicker: View {
    @Binding var quietHours: TimeWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Toggle(L10n.text("quiet_hours_title"), isOn: Binding(
                get: { quietHours != nil },
                set: { enabled in
                    quietHours = enabled ? TimeWindow.previewQuietHours() : nil
                }
            ))

            Text(L10n.text("quiet_hours_description"))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)

            if let binding = quietHoursBinding {
                HStack(spacing: AppSpacing.medium) {
                    DatePicker(
                        L10n.text("quiet_hours_start"),
                        selection: Binding(
                            get: { binding.wrappedValue.start },
                            set: { newStart in
                                binding.wrappedValue = TimeWindow(
                                    start: newStart,
                                    end: binding.wrappedValue.end,
                                    id: "quiet-hours"
                                )
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()

                    Text("–")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)

                    DatePicker(
                        L10n.text("quiet_hours_end"),
                        selection: Binding(
                            get: { binding.wrappedValue.end },
                            set: { newEnd in
                                binding.wrappedValue = TimeWindow(
                                    start: binding.wrappedValue.start,
                                    end: newEnd,
                                    id: "quiet-hours"
                                )
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
