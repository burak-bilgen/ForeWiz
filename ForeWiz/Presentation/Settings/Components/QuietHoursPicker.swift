import SwiftUI

struct QuietHoursPicker: View {
    @Binding var quietHours: TimeWindow?

    private let accentColor = Color(red: 1.0, green: 0.45, blue: 0.45)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(accentColor.opacity(0.16))
                        .frame(width: 34, height: 34)
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(accentColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text("quiet_hours_title"))
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(L10n.text("quiet_hours_description"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.38))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
                Spacer(minLength: 8)
                Toggle("", isOn: Binding(
                    get: { quietHours != nil },
                    set: { enabled in
                        Task { await HapticEngine.shared.selectionChanged() }
                        quietHours = enabled ? TimeWindow.previewQuietHours() : nil
                    }
                ))
                .tint(accentColor)
                .labelsHidden()
            }
            .padding(.vertical, 8)

            if let binding = quietHoursBinding {
                VStack(spacing: 10) {
                    VStack(spacing: 6) {
                        Text(L10n.text("quiet_hours_start"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .textCase(.uppercase)
                            .tracking(0.4)
                        DatePicker(
                            "",
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
                        .colorScheme(.dark)
                        .tint(accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(spacing: 6) {
                        Text(L10n.text("quiet_hours_end"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .textCase(.uppercase)
                            .tracking(0.4)
                        DatePicker(
                            "",
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
                        .colorScheme(.dark)
                        .tint(accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: quietHours != nil)
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
