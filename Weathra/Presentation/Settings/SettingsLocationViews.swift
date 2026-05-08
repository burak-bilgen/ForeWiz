import SwiftUI

struct SavedLocationsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        ForEach(profile.savedLocations) { location in
            NavigationLink {
                SavedLocationDetailView(location: location, onSave: { updated in
                    updateLocation(updated)
                }, onDelete: {
                    deleteLocation(location)
                })
            } label: {
                SavedLocationRow(
                    location: location,
                    isSelected: location.id == profile.selectedLocationID
                )
            }
        }

        Button(action: addLocation) {
            Label(L10n.text("settings_add_location"), systemImage: "plus.circle.fill")
                .foregroundStyle(.blue)
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
        Label {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(location.name)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                Text(location.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: location.id == "current-location"
                  ? "location.fill"
                  : "mappin.and.ellipse")
                .foregroundStyle(.blue)
        }
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
        Form {
            Section {
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if location.id != "current-location" {
                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label(L10n.text("settings_delete_location"), systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
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
        Section {
            Button(role: .destructive) {
                showConfirmation = true
            } label: {
                Label(L10n.text("settings_reset_confirm"), systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text(L10n.text("settings_reset_title"))
        } footer: {
            Text(L10n.text("settings_reset_subtitle"))
        }
    }
}
