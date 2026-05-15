import SwiftUI

struct QuietHoursPicker: View {
    @Binding var quietHours: TimeWindow?

    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    GlassIcon(systemName: "moon.zzz.fill", color: .liquidAccent)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.text("quiet_hours_title"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(L10n.text("quiet_hours_description"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)

                    Spacer(minLength: 8)

                    Toggle("", isOn: Binding(
                        get: { quietHours != nil },
                        set: { enabled in
                            HapticEngine.shared.selectionChanged()
                            quietHours = enabled ? TimeWindow.previewQuietHours() : nil
                        }
                    ))
                    .tint(.liquidAccent)
                    .labelsHidden()
                }
                .padding(.vertical, 8)

                if let binding = quietHoursBinding {
                    VStack(spacing: 10) {
                        GlassDatePicker(
                            title: L10n.text("quiet_hours_start"),
                            selection: Binding(
                                get: { binding.wrappedValue.start },
                                set: { newStart in
                                    binding.wrappedValue = TimeWindow(
                                        start: newStart,
                                        end: binding.wrappedValue.end,
                                        id: "quiet-hours"
                                    )
                                }
                            )
                        )

                        GlassDatePicker(
                            title: L10n.text("quiet_hours_end"),
                            selection: Binding(
                                get: { binding.wrappedValue.end },
                                set: { newEnd in
                                    binding.wrappedValue = TimeWindow(
                                        start: binding.wrappedValue.start,
                                        end: newEnd,
                                        id: "quiet-hours"
                                    )
                                }
                            )
                        )
                    }
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: quietHours != nil)
                }
            }
        }
    }

    private var quietHoursBinding: Binding<TimeWindow>? {
        guard quietHours != nil else { return nil }
        return Binding(
            get: { quietHours ?? TimeWindow.previewQuietHours() },
            set: { quietHours = $0 }
        )
    }
}

// MARK: - Glass Date Picker

struct GlassDatePicker: View {
    let title: String
    @Binding var selection: Date

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.liquidAccent.opacity(0.7))
                .textCase(.uppercase)
                .tracking(0.8)

            DatePicker(
                "",
                selection: $selection,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .colorScheme(.dark)
            .tint(.liquidAccent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.liquidAccent.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.liquidAccent.opacity(0.1), lineWidth: 0.5)
        )
    }
}
