import CoreLocation
import MapKit
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
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .sheet(isPresented: $showAddLocation) {
            AddLocationMapView(savedLocations: $savedLocations)
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

// MARK: - Add Location Map View

private struct AddLocationMapView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var savedLocations: [SavedLocation]

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                if let coord = selectedCoordinate {
                    Annotation("", coordinate: coord) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.3))
                                .frame(width: 44, height: 44)
                            Circle()
                                .fill(Color(red: 0.4, green: 0.7, blue: 1.0))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(.white)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .top)

            VStack {
                searchBar
                Spacer()
                bottomPanel
            }
        }
        .onChange(of: cameraPosition) { newPosition in
            if let region = newPosition.region {
                selectedCoordinate = region.center
            }
        }
    }

    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.5))

                    TextField(L10n.text("settings_search_location"), text: $searchText)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .overlay {
                            if isSearching && !searchText.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.7)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                        .onChange(of: searchText) { _, newValue in
                            searchTask?.cancel()
                            guard !newValue.isEmpty else {
                                searchResults = []
                                return
                            }
                            searchTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 400_000_000)
                                guard !Task.isCancelled else { return }
                                search()
                            }
                        }
                        .onSubmit { searchTask?.cancel(); search() }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: isSearching ? "magnifyingglass" : "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                        .disabled(isSearching)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12))
                .cornerRadius(12)

                Button {
                    dismiss()
                } label: {
                    Text(L10n.text("settings_cancel"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 12)

            if !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults.prefix(5), id: \.self) { item in
                        SearchResultRow(item: item) {
                            selectMapItem(item)
                        }
                        if item != searchResults.prefix(5).last {
                            Divider().background(Color.white.opacity(0.1))
                        }
                    }
                }
                .background(Color(red: 0.06, green: 0.10, blue: 0.20))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }
        }
    }

    private var bottomPanel: some View {
        VStack(spacing: 16) {
            if let item = selectedMapItem {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name ?? "Unknown")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let addr = item.placemark.title {
                        Text(addr)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            }

            Button {
                addSelectedLocation()
            } label: {
                Text(L10n.text("location_picker_add_button"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.1, green: 0.35, blue: 0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
            .disabled(selectedCoordinate == nil)
            .opacity(selectedCoordinate == nil ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 34)
        .background(
            LinearGradient(
                colors: [Color.clear, Color(red: 0.04, green: 0.08, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func search() {
        guard !searchText.isEmpty else { return }
        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = .address

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            isSearching = false
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }

    private func selectMapItem(_ item: MKMapItem) {
        selectedMapItem = item
        selectedCoordinate = item.placemark.coordinate
        searchText = ""
        searchResults = []

        let region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        cameraPosition = .region(region)
    }

    private func addSelectedLocation() {
        guard let coord = selectedCoordinate else { return }

        let name = selectedMapItem?.name ?? "Selected Location"
        let address = selectedMapItem?.placemark.title ?? ""

        let location = SavedLocation(
            name: name,
            latitude: coord.latitude,
            longitude: coord.longitude,
            address: address
        )
        savedLocations.append(location)
        dismiss()
    }
}

private struct SearchResultRow: View {
    let item: MKMapItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name ?? "Unknown")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let addr = item.placemark.title {
                        Text(addr)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Background

private struct LocationPickerBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let height = max(geometry.size.height, 1)
            let orbSize = min(width, height) * 0.58

            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.06, green: 0.12, blue: 0.26)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.07))
                    .frame(width: orbSize, height: orbSize)
                    .blur(radius: orbSize * 0.22)
                    .position(x: width * 0.78, y: height * 0.08)
            }
            .frame(width: width, height: height)
            .clipped()
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
        .padding(.horizontal, 16)
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

    private var isCurrentLocation: Bool {
        location.id == "current-location"
    }

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

// MARK: - Add location field

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
