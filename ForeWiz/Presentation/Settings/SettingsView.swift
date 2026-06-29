import SwiftUI
import WizPathKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var homeLocation: SavedLocation?
    @Binding var workLocation: SavedLocation?
    @Binding var commuteModeRaw: String

    let onSave: () -> Void

    @State private var showHomePicker = false
    @State private var showWorkPicker = false
    @State private var appears = false

    var body: some View {
        ZStack {
            LiquidOrbBackground(palette: .clearSky)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerSection
                        .padding(.top, 48)

                    homeLocationSection
                    workLocationSection
                    commuteModeSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
        .interactiveDismissDisabled()
        .onAppear { animatePage() }
        .overlay(alignment: .topTrailing) {
            Button {
                HapticEngine.shared.light()
                onSave()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
            .staggerEntrance(index: 1, appeared: appears)
        }
        .sheet(isPresented: $showHomePicker) {
            locationPickerSheet(for: .home)
        }
        .sheet(isPresented: $showWorkPicker) {
            locationPickerSheet(for: .work)
        }
    }

    private func animatePage() {
        withAnimation(AppTheme.slowEaseOut) {
            appears = true
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.liquidAccent.opacity(0.12))
                    .frame(width: 80, height: 80)
                    .blur(radius: 8)
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 72, height: 72)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.liquidAccent)
            }
            .floating(amplitude: 7, duration: 3.5)
            .staggerEntrance(index: 0, appeared: appears)

            Text(L10n.text("settings_home_location"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .staggerEntrance(index: 1, appeared: appears)

            Text(L10n.text("settings_commute_mode"))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .staggerEntrance(index: 2, appeared: appears)
        }
    }

    private var homeLocationSection: some View {
        LiquidGlassCard(accentColor: AppTheme.liquidAccent, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel(icon: "house.fill", text: L10n.text("settings_home_location"))

                if let home = homeLocation {
                    locationRow(location: home, isHome: true)
                } else {
                    emptyLocationRow(isHome: true)
                }

                if homeLocation != nil {
                    Button {
                        HapticEngine.shared.medium()
                        homeLocation = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 12))
                            Text(L10n.text("action_clear"))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.ember)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(AppTheme.ember.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.ember.opacity(0.25), lineWidth: 1))
                    }
                }

                if let home = homeLocation, let work = workLocation,
                   home.latitude == work.latitude, home.longitude == work.longitude {
                    sameLocationWarning
                }
            }
        }
        .staggerEntrance(index: 3, appeared: appears)
    }

    private var workLocationSection: some View {
        LiquidGlassCard(accentColor: AppTheme.liquidAccent, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel(icon: "briefcase.fill", text: L10n.text("settings_work_location"))

                if let work = workLocation {
                    locationRow(location: work, isHome: false)
                } else {
                    emptyLocationRow(isHome: false)
                }

                if workLocation != nil {
                    Button {
                        HapticEngine.shared.medium()
                        workLocation = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 12))
                            Text(L10n.text("action_clear"))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.ember)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(AppTheme.ember.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.ember.opacity(0.25), lineWidth: 1))
                    }
                }
            }
        }
        .staggerEntrance(index: 4, appeared: appears)
    }

    private var commuteModeSection: some View {
        LiquidGlassCard(accentColor: AppTheme.liquidAccent, innerPadding: 14) {
            VStack(alignment: .leading, spacing: 14) {
                sectionLabel(icon: "arrow.triangle.swap", text: L10n.text("settings_commute_mode"))

                HStack(spacing: 8) {
                    ForEach(TravelMode.allCases, id: \.self) { mode in
                        let selected = commuteModeRaw == mode.rawValue
                        Button {
                            HapticEngine.shared.selectionChanged()
                            withAnimation(AppTheme.cardSpring) {
                                commuteModeRaw = mode.rawValue
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 18))
                                Text(L10n.text(mode.localizedKey))
                                    .font(.system(size: 12, weight: selected ? .bold : .medium, design: .rounded))
                            }
                            .foregroundStyle(selected ? AppTheme.liquidAccent : .white.opacity(0.45))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                selected
                                    ? AppTheme.liquidAccent.opacity(0.12)
                                    : .white.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selected ? AppTheme.liquidAccent.opacity(0.35) : .white.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .staggerEntrance(index: 5, appeared: appears)
    }

    private func locationRow(location: SavedLocation, isHome: Bool) -> some View {
        Button {
            HapticEngine.shared.medium()
            if isHome { showHomePicker = true } else { showWorkPicker = true }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.liquidAccent.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: isHome ? "house.fill" : "briefcase.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.liquidAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if !location.address.isEmpty {
                        Text(location.address)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(12)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.liquidAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func emptyLocationRow(isHome: Bool) -> some View {
        Button {
            HapticEngine.shared.medium()
            if isHome { showHomePicker = true } else { showWorkPicker = true }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 38, height: 38)
                    Image(systemName: isHome ? "house.fill" : "briefcase.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text(isHome ? "commute_home_prompt" : "commute_work_prompt"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.liquidAccent)
            }
            .padding(12)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var sameLocationWarning: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.yellow.opacity(0.8))
                .padding(.top, 1)
            Text(L10n.text("settings_same_home_work_warning"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .lineSpacing(2)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.yellow.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.yellow.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func locationPickerSheet(for type: LocationType) -> some View {
        NavigationStack {
            ModernAddLocationView { location in
                var updated = location
                updated.locationType = type
                switch type {
                case .home:
                    homeLocation = updated
                case .work:
                    workLocation = updated
                case .other:
                    break
                }
            }
        }
    }

    private func sectionLabel(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
    }
}
