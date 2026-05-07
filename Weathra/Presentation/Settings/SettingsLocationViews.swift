import SwiftUI

struct SavedLocationsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "mappin.and.ellipse",
            title: L10n.text("settings_saved_locations_title"),
            subtitle: L10n.text("settings_saved_locations_subtitle")
        ) {
            VStack(spacing: AppSpacing.small) {
                ForEach(profile.savedLocations) { location in
                    NavigationLink {
                        SavedLocationDetailView(location: location, onSave: { updated in
                            updateLocation(updated)
                        }, onDelete: {
                            deleteLocation(location)
                        })
                    } label: {
                        SavedLocationRow(location: location, isSelected: location.id == profile.selectedLocationID)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                Button(action: addLocation) {
                    Label(L10n.text("settings_add_location"), systemImage: "plus.circle.fill")
                        .font(AppTypography.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
            }
        }
    }

    private func updateLocation(_ updated: SavedLocation) {
        guard let index = profile.savedLocations.firstIndex(where: { $0.id == updated.id }) else {
            return
        }

        profile.savedLocations[index] = updated
    }

    private func deleteLocation(_ location: SavedLocation) {
        guard location.id != "current-location" else {
            return
        }

        profile.savedLocations.removeAll { $0.id == location.id }

        if profile.selectedLocationID == location.id {
            profile.selectedLocationID = "current-location"
        }
    }

    private func addLocation() {
        let newLocation = SavedLocation(
            name: L10n.text("settings_new_location"),
            latitude: 0,
            longitude: 0,
            address: L10n.text("settings_search_location")
        )

        profile.savedLocations.append(newLocation)
    }
}

struct SavedLocationRow: View {
    let location: SavedLocation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: location.id == "current-location" ? "location.fill" : "mappin.and.ellipse")
                .font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text(location.address)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.small)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xSmall)
        .background(
            AppTheme.elevatedSurface.opacity(0.86),
            in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
        )
    }
}

struct SavedLocationDetailView: View {
    @State private var name: String
    @State private var address: String

    let location: SavedLocation
    let onSave: (SavedLocation) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(location: SavedLocation, onSave: @escaping (SavedLocation) -> Void, onDelete: @escaping () -> Void) {
        self.location = location
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: location.name)
        _address = State(initialValue: location.address)
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                GlassCard {
                    VStack(spacing: AppSpacing.medium) {
                        LabeledContent(L10n.text("settings_location_name")) {
                            TextField(L10n.text("settings_location_name"), text: $name)
                                .multilineTextAlignment(.trailing)
                        }

                        LabeledContent(L10n.text("settings_address")) {
                            TextField(L10n.text("settings_address"), text: $address)
                                .multilineTextAlignment(.trailing)
                        }

                        LabeledContent(L10n.text("settings_coordinates")) {
                            let formattedLat = location.latitude.formatted(
                                .number.precision(.fractionLength(4))
                            )
                            let formattedLon = location.longitude.formatted(
                                .number.precision(.fractionLength(4))
                            )
                            Text("\(formattedLat), \(formattedLon)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }

                if location.id != "current-location" {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label(L10n.text("settings_delete_location"), systemImage: "trash")
                            .font(AppTypography.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(L10n.text("settings_edit_location"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.text("settings_save")) {
                    var updated = location
                    updated.name = name
                    updated.address = address
                    onSave(updated)
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

struct ResetSection: View {
    @Binding var showConfirmation: Bool

    var body: some View {
        SettingsCard(
            icon: "arrow.counterclockwise.circle.fill",
            title: L10n.text("settings_reset_title"),
            subtitle: L10n.text("settings_reset_subtitle")
        ) {
            Button(
                action: { showConfirmation = true },
                label: {
                    Label(L10n.text("settings_reset_confirm"), systemImage: "arrow.counterclockwise")
                        .font(AppTypography.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
            )
            .buttonStyle(.bordered)
            .tint(AppTheme.danger)
        }
    }
}
