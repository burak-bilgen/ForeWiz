import SwiftUI

// MARK: - Departure Optimizer Sheet

public struct WizPathDepartureOptimizerSheet: View {
    let route: WizPathRoute
    let onSelectTime: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHour = 8
    @State private var selectedMinute = 0

    public init(route: WizPathRoute, onSelectTime: @escaping (Date) -> Void) {
        self.route = route; self.onSelectTime = onSelectTime
    }

    public var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 20) {
                    LiquidGlassCard(accentColor: .success, innerPadding: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.checkmark").font(.system(size: 40)).foregroundStyle(Color.success).symbolRenderingMode(.multicolor)
                            Text(WizPathKitL10n.text("wizpath_optimize_departure")).font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                            Text(WizPathKitL10n.text("wizpath_optimize_departure_desc")).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                    }
                    LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 20) {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                WizPathTimePickerColumn(title: WizPathKitL10n.text("wizpath_hour"), range: Array(0..<24), selection: $selectedHour, format: "%02d")
                                Text(":").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.secondary).offset(y: -10)
                                WizPathTimePickerColumn(title: WizPathKitL10n.text("wizpath_minute"), range: Array(stride(from: 0, to: 60, by: 5)), selection: $selectedMinute, format: "%02d")
                            }
                            VStack(spacing: 8) {
                                Text(WizPathKitL10n.text("wizpath_quick_times")).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                                LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 8) {
                                    ForEach([6, 8, 10, 12, 14, 16, 18, 20], id: \.self) { hour in
                                        WizPathQuickTimeChip(hour: hour, isSelected: selectedHour == hour && selectedMinute == 0) { selectedHour = hour; selectedMinute = 0 }
                                    }
                                }
                            }
                        }
                    }
                    Spacer(minLength: 20)
                    Button {
                        let calendar = Calendar.current; var components = calendar.dateComponents([.year, .month, .day], from: Date())
                        components.hour = selectedHour; components.minute = selectedMinute
                        if let date = calendar.date(from: components) { onSelectTime(date) }
                    } label: {
                        HStack(spacing: 8) { Image(systemName: "checkmark.circle.fill").font(.system(size: 18)); Text(WizPathKitL10n.text("wizpath_set_departure_time")).font(.system(size: 16, weight: .bold)) }
                            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(LinearGradient(colors: [Color.liquidAccent, Color.liquidAccentSoft], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).shadow(color: .liquidAccent.opacity(0.3), radius: 12, y: 4)
                    }.contentShape(Rectangle()).buttonStyle(.plain).padding(.bottom, 24)
                }.padding(20)
            }
        }
        .navigationTitle(WizPathKitL10n.text("wizpath_departure_optimizer"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(WizPathKitL10n.text("wizpath_done")) { dismiss() }.foregroundStyle(Color.liquidAccent) } }
    }
}

// MARK: - Time Picker Column

public struct WizPathTimePickerColumn: View {
    let title: String; let range: [Int]; @Binding var selection: Int; let format: String
    public init(title: String, range: [Int], selection: Binding<Int>, format: String) { self.title = title; self.range = range; self._selection = selection; self.format = format }
    public var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).textCase(.uppercase).tracking(0.8)
            Picker("", selection: $selection) {
                ForEach(range, id: \.self) { value in Text(String(format: format, value)).font(.system(size: 20, design: .rounded)).tag(value) }
            }.pickerStyle(.wheel).frame(width: 80).colorScheme(.dark)
        }
    }
}

// MARK: - Quick Time Chip

public struct WizPathQuickTimeChip: View {
    let hour: Int; let isSelected: Bool; let action: () -> Void
    public init(hour: Int, isSelected: Bool, action: @escaping () -> Void) { self.hour = hour; self.isSelected = isSelected; self.action = action }
    public var body: some View {
        Button(action: action) {
            Text(String(format: "%02d:00", hour)).font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.8)).frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(isSelected ? Color.liquidAccent : Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(isSelected ? Color.liquidAccent : Color.white.opacity(0.08), lineWidth: isSelected ? 1 : 0.5))
        }.contentShape(Rectangle()).buttonStyle(.plain)
    }
}
