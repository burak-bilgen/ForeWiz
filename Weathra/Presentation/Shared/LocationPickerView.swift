import SwiftUI

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String
    let onSelect: (SavedLocation) -> Void

    @State private var isEditing = false
    @State private var showAddLocation = false

    var body: some View {
        ZStack {
            LocationPickerBackground().ignoresSafeArea()
            VStack(spacing: 0) {
                LocationPickerNavBar(
                    isEditing: $isEditing,
                    showMultipleLocations: savedLocations.count > 1,
                    onAdd: { showAddLocation = true },
                    onClose: { dismiss() }
                )

                if savedLocations.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 80, height: 80)
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.white.opacity(0.35))
                        }
                        Text(L10n.text("location_picker_empty"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(L10n.text("location_picker_empty_hint"))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(savedLocations) { location in
                                LocationRow(
                                    location: location,
                                    isSelected: location.id == selectedLocationID,
                                    isEditing: isEditing,
                                    onTap: { select(location) },
                                    onDelete: { deleteLocation(location) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .sheet(isPresented: $showAddLocation) {
            AddLocationView(savedLocations: $savedLocations)
        }
        .dynamicTypeSize(.large ... .xxxLarge)
    }

    private func select(_ location: SavedLocation) {
        guard !isEditing else { return }
        HapticManager.light()
        selectedLocationID = location.id
        onSelect(location)
        dismiss()
    }

    private func deleteLocation(_ location: SavedLocation) {
        guard location.id != "current-location" else { return }
        savedLocations.removeAll { $0.id == location.id }
    }
}

// MARK: - Background

private struct LocationPickerBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.06, green: 0.12, blue: 0.26)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.07))
                .frame(width: 250).blur(radius: 55)
                .offset(x: 80, y: -180)
        }
    }
}

// MARK: - Nav bar

private struct LocationPickerNavBar: View {
    @Binding var isEditing: Bool
    let showMultipleLocations: Bool
    let onAdd: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if showMultipleLocations {
                Button {
                    HapticManager.light()
                    isEditing.toggle()
                } label: {
                    Text(isEditing ? L10n.text("location_picker_done") : L10n.text("location_picker_edit"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                }
            }
            Spacer()
            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            Button(action: onClose) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .bottom)
    }
}

// MARK: - Location row

private struct LocationRow: View {
    let location: SavedLocation
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    private var isCurrentLocation: Bool { location.id == "current-location" }

    var body: some View {
        HStack(spacing: 14) {
            if isEditing && !isCurrentLocation {
                Button(action: onDelete) {
                    ZStack {
                        Circle().fill(Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.15)).frame(width: 26, height: 26)
                        Image(systemName: "minus").font(.system(size: 11, weight: .bold)).foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            Button(action: onTap) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isCurrentLocation
                                  ? Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.15)
                                  : Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.12))
                            .frame(width: 38, height: 38)
                        Image(systemName: isCurrentLocation ? "location.fill" : "mappin.and.ellipse")
                            .font(.system(size: 15))
                            .foregroundStyle(isCurrentLocation
                                             ? Color(red: 0.4, green: 0.7, blue: 1.0)
                                             : Color(red: 1.0, green: 0.5, blue: 0.5))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        if !location.address.isEmpty {
                            Text(location.address)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.4))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                    .layoutPriority(1)

                    Spacer(minLength: 8)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected
                        ? Color(red: 0.4, green: 0.85, blue: 0.6).opacity(0.25)
                        : Color.white.opacity(0.07), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}

// MARK: - Add location sheet

private struct AddLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var savedLocations: [SavedLocation]

    @State private var name = ""
    @State private var latitudeText = "41.0082"
    @State private var longitudeText = "28.9784"

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.06, green: 0.12, blue: 0.26)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    HStack {
                        Button(L10n.text("location_picker_cancel")) {
                            dismiss()
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)

                        Spacer(minLength: 12)

                        Button(L10n.text("location_picker_add_button")) { addLocation() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(
                                name.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.white.opacity(0.25)
                                : Color(red: 0.4, green: 0.7, blue: 1.0)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.80)
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    Text(L10n.text("location_picker_add_title"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .bottom)

                ScrollView {
                    VStack(spacing: 20) {
                        AddLocationField(
                            label: L10n.text("location_picker_name_section"),
                            placeholder: L10n.text("location_picker_name_placeholder"),
                            text: $name,
                            keyboardType: .default
                        )
                        AddLocationField(
                            label: L10n.text("location_picker_latitude"),
                            placeholder: "41.0082",
                            text: $latitudeText,
                            keyboardType: .decimalPad
                        )
                        AddLocationField(
                            label: L10n.text("location_picker_longitude"),
                            placeholder: "28.9784",
                            text: $longitudeText,
                            keyboardType: .decimalPad
                        )
                        Text(L10n.text("location_picker_default_coords_note"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func addLocation() {
        guard let lat = Double(latitudeText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(longitudeText.trimmingCharacters(in: .whitespaces)),
              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
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

private struct AddLocationField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.45))
                .textCase(.uppercase)
                .tracking(0.5)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .keyboardType(keyboardType)
                .padding(14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
}
