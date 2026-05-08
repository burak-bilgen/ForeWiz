import SwiftUI

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String
    let onSelect: (SavedLocation) -> Void

    @State private var isEditing = false
    @State private var showAddLocation = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if savedLocations.count > 1 {
                    Button(isEditing ? L10n.text("location_picker_done") : L10n.text("location_picker_edit")) {
                        isEditing.toggle()
                    }
                    .padding(.leading, 20)
                }
                Spacer()
                Button {
                    showAddLocation = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                Button(L10n.text("location_picker_close")) {
                    dismiss()
                }
                .fontWeight(.semibold)
                .padding(.trailing, 20)
            }
            .padding(.vertical, 12)
            .background(.regularMaterial)

            if savedLocations.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(L10n.text("location_picker_empty"))
                        .font(.headline)
                    Text(L10n.text("location_picker_empty_hint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(savedLocations) { location in
                        Button {
                            select(location)
                        } label: {
                            LocationRowContent(
                                location: location,
                                isSelected: location.id == selectedLocationID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        if isEditing { deleteLocations(at: offsets) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .sheet(isPresented: $showAddLocation) {
            AddLocationView(savedLocations: $savedLocations)
        }
    }

    private func select(_ location: SavedLocation) {
        guard isEditing == false else { return }
        selectedLocationID = location.id
        onSelect(location)
        dismiss()
    }

    private func deleteLocations(at offsets: IndexSet) {
        let deletableIDs = offsets.compactMap { index in
            savedLocations.indices.contains(index) ? savedLocations[index].id : nil
        }
        savedLocations.removeAll { location in
            deletableIDs.contains(location.id) && location.id != "current-location"
        }
    }
}

private struct LocationRowContent: View {
    let location: SavedLocation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: location.id == "current-location" ? "location.fill" : "mappin.and.ellipse")
                .font(.title3)
                .frame(width: 32, height: 32)
                .foregroundStyle(location.id == "current-location" ? .blue : .primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(.body)
                    .fontWeight(.semibold)
                if !location.address.isEmpty {
                    Text(location.address)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 12)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

private struct AddLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var savedLocations: [SavedLocation]

    @State private var name = ""
    @State private var latitudeText = "41.0082"
    @State private var longitudeText = "28.9784"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(L10n.text("location_picker_cancel")) { dismiss() }
                Spacer()
                Text(L10n.text("location_picker_add_title"))
                    .font(.headline)
                Spacer()
                Button(L10n.text("location_picker_add_button")) { addLocation() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(.regularMaterial)

            Form {
                Section(L10n.text("location_picker_name_section")) {
                    TextField(L10n.text("location_picker_name_placeholder"), text: $name)
                }

                Section(L10n.text("location_picker_coordinates")) {
                    TextField(L10n.text("location_picker_latitude"), text: $latitudeText)
                        .keyboardType(.decimalPad)
                    TextField(L10n.text("location_picker_longitude"), text: $longitudeText)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Text(L10n.text("location_picker_default_coords_note"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func addLocation() {
        guard let lat = Double(latitudeText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(longitudeText.trimmingCharacters(in: .whitespaces)),
              name.trimmingCharacters(in: .whitespaces).isEmpty == false else {
            return
        }

        let location = SavedLocation(
            name: name.trimmingCharacters(in: .whitespaces),
            latitude: lat,
            longitude: lon,
            address: String(format: "%.4f, %.4f", lat, lon)
        )
        savedLocations.append(location)
        dismiss()
    }
}
