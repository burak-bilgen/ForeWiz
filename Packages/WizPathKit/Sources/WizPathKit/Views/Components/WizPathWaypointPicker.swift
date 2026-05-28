import SwiftUI
import CoreLocation

// MARK: - Waypoint Picker Sheet

public struct WizPathWaypointPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let waypoints: [SmartStop]
    let onNavigate: (Set<UUID>) -> Void
    let onNavigateWithoutStops: () -> Void

    @State private var localSelectedIds: Set<UUID>

    public init(
        waypoints: [SmartStop],
        onNavigate: @escaping (Set<UUID>) -> Void,
        onNavigateWithoutStops: @escaping () -> Void
    ) {
        self.waypoints = waypoints
        self.onNavigate = onNavigate
        self.onNavigateWithoutStops = onNavigateWithoutStops
        self._localSelectedIds = State(initialValue: Set(waypoints.map(\.id)))
    }

    public var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 20) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.liquidAccent.opacity(0.18))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Color.liquidAccent)
                                    .shadow(color: Color.liquidAccent.opacity(0.4), radius: 8)
                            }

                            Text(WizPathKitL10n.text("wizpath_waypoint_picker_title"))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text(WizPathKitL10n.text("wizpath_waypoint_picker_subtitle"))
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)

                    // Select / Deselect All
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.76)) {
                                localSelectedIds = Set(waypoints.map(\.id))
                            }
                            HapticEngine.shared.selectionChanged()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                Text(WizPathKitL10n.text("wizpath_waypoint_picker_select_all"))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(Color.liquidAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.liquidAccent.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .opacity(localSelectedIds.count == waypoints.count ? 0.35 : 1.0)

                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.76)) {
                                localSelectedIds = []
                            }
                            HapticEngine.shared.selectionChanged()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "circle.slash")
                                    .font(.system(size: 12))
                                Text(WizPathKitL10n.text("wizpath_waypoint_picker_deselect_all"))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.06), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .opacity(localSelectedIds.isEmpty ? 0.35 : 1.0)

                        Spacer()

                        Text(verbatim: "\(localSelectedIds.count)/\(waypoints.count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 16)

                    // Waypoint List or Empty State
                    if waypoints.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary.opacity(0.4))
                            Text(WizPathKitL10n.text("wizpath_waypoint_picker_empty"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 16)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(waypoints) { stop in
                                waypointRow(stop: stop)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Action Buttons
                    VStack(spacing: 10) {
                        // Primary: Navigate with selected stops
                        LiquidGlassButton(
                            navigateButtonTitle,
                            icon: "map.fill",
                            style: .primary,
                            haptic: .medium,
                            isFullWidth: true
                        ) {
                            HapticEngine.shared.success()
                            onNavigate(localSelectedIds)
                            dismiss()
                        }

                        // Secondary: Navigate without any stops
                        if !waypoints.isEmpty {
                            Button {
                                HapticEngine.shared.light()
                                onNavigateWithoutStops()
                                dismiss()
                            } label: {
                                Text(WizPathKitL10n.text("wizpath_waypoint_picker_navigate_without"))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .padding(.vertical, 8)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func waypointRow(stop: SmartStop) -> some View {
        let isSelected = localSelectedIds.contains(stop.id)
        let accentColor = Color(hex: stop.category.color)

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    localSelectedIds.remove(stop.id)
                } else {
                    localSelectedIds.insert(stop.id)
                }
            }
            HapticEngine.shared.selectionChanged()
        } label: {
            HStack(spacing: 14) {
                // Selection Indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? accentColor.opacity(0.2) : .white.opacity(0.04))
                        .frame(width: 44, height: 44)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? accentColor : .white.opacity(0.3))
                }

                // Category Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: stop.category.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.displayTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        // ETA
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 8))
                            Text(stop.etaDisplay)
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)

                        // Safety badge
                        if stop.safetyStatus != .safe {
                            Circle()
                                .fill(Color(hex: stop.safetyStatus.color))
                                .frame(width: 4, height: 4)

                            Text(stop.safetyStatus.localizedTitle)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: stop.safetyStatus.color))
                        }

                        // Distance
                        if stop.distanceFromRoute > 0 {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 3, height: 3)

                            Text(WizPathKitFormatters.formattedDistance(stop.distanceFromRoute))
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer(minLength: 0)

                // Weather indicator
                if let weather = stop.weatherAtArrival {
                    VStack(spacing: 1) {
                        Image(systemName: weather.iconName)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: weather.severity.colorHex))
                            .symbolRenderingMode(.multicolor)
                        Text(WizPathKitL10n.formatted("wizpath_temperature_format", Int(weather.temperature)))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 36)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isSelected ? accentColor.opacity(0.3) : .white.opacity(0.06),
                                lineWidth: isSelected ? 1.5 : 0.5
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }

    private var navigateButtonTitle: String {
        if localSelectedIds.isEmpty {
            return WizPathKitL10n.text("wizpath_waypoint_picker_navigate_direct")
        }
        let count = localSelectedIds.count
        let formatKey = count == 1 ? "wizpath_waypoint_picker_navigate_singular" : "wizpath_waypoint_picker_navigate_plural"
        return WizPathKitL10n.formatted(formatKey, count)
    }

}


