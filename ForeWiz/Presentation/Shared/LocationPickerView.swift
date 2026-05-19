import CoreLocation
import MapKit
import SwiftUI

// MARK: - LocationPickerView

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String
    let onSelect: (SavedLocation) -> Void
    let onLocationsChanged: ([SavedLocation]) -> Void

    @State private var showAddLocation = false
    @State private var editMode: EditMode = .inactive
    @State private var appears = false

    var body: some View {
        ZStack {
            AnimatedOrbBackground(
                primary: Color(red: 0.25, green: 0.48, blue: 0.92),
                secondary: Color(red: 0.15, green: 0.32, blue: 0.75),
                tertiary: Color(red: 0.40, green: 0.65, blue: 1.0)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if savedLocations.isEmpty {
                    emptyState
                } else {
                    locationList
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { appears = true }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showAddLocation) {
            ModernAddLocationView { location in
                savedLocations.append(location)
                onLocationsChanged(savedLocations)
            }
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 8) {
            Button {
                HapticEngine.shared.light()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            Text(L10n.text("location_picker_title"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    showAddLocation = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 1.0))
                }

                if savedLocations.count > 1 {
                    Button {
                        withAnimation(AppTheme.cardSpring) {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    } label: {
                        Text(editMode == .active ? L10n.text("location_picker_done") : L10n.text("location_picker_edit"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 1.0))
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : -10)
        .animation(AppTheme.defaultEaseOut, value: appears)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 72, height: 72)
                Image(systemName: "mappin.slash")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .scaleEffect(appears ? 1 : 0.6)
            .animation(AppTheme.sheetSpring.delay(AppTheme.defaultDelay), value: appears)

            Text(L10n.text("location_picker_empty"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text(L10n.text("location_picker_empty_hint"))
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showAddLocation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L10n.text("location_picker_add_first"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.15, green: 0.4, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .buttonStyle(.fullTapArea)
            .opacity(appears ? 1 : 0)
            .animation(AppTheme.slowEaseOut.delay(AppTheme.defaultDelay + 0.17), value: appears)

            Spacer()
        }
    }

    // MARK: - Location List

    private var locationList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                // Current location always on top
                if let current = savedLocations.first(where: { $0.id == "current-location" }) {
                    currentLocationCard(current)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                // Other locations
                let others = savedLocations.filter { $0.id != "current-location" }
                if !others.isEmpty {
                    if savedLocations.contains(where: { $0.id == "current-location" }) {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                            Text(L10n.text("location_picker_saved"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.35))
                                .textCase(.uppercase)
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }

                    ForEach(others) { location in
                        LocationCard(
                            location: location,
                            isSelected: location.id == selectedLocationID,
                            isEditing: editMode == .active,
                            onTap: { selectLocation(location) },
                            onDelete: { deleteLocation(location) }
                        )
                        .padding(.horizontal, 16)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).animation(AppTheme.cardSpring),
                            removal: .opacity.combined(with: .scale(scale: 0.9))
                        ))
                    }
                }

                // Add location button
                Button {
                    showAddLocation = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text(L10n.text("location_picker_add_button"))
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 1.0))
                    .padding(16)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.fullTapArea)
                .padding(.horizontal, 16)
                .padding(.top, 4)

                Spacer().frame(height: 24)
            }
        }
    }

    // MARK: - Current Location Hero

    private func currentLocationCard(_ location: SavedLocation) -> some View {
        Button {
            selectLocation(location)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.72, blue: 1.0).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 1.0))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)

                    Text(L10n.text("location_currently_selected"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                }

                Spacer()

                if location.id == selectedLocationID {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.72, blue: 1.0).opacity(0.08),
                        Color(red: 0.4, green: 0.72, blue: 1.0).opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        location.id == selectedLocationID
                            ? Color(red: 0.4, green: 0.85, blue: 0.6).opacity(0.3)
                            : Color(red: 0.4, green: 0.72, blue: 1.0).opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.fullTapArea)
    }

    // MARK: - Actions

    private func selectLocation(_ location: SavedLocation) {
        guard editMode == .inactive else { return }
        HapticEngine.shared.light()
        withAnimation(AppTheme.pressSpring) {
            selectedLocationID = location.id
        }
        onSelect(location)
        dismiss()
    }

    private func deleteLocation(_ location: SavedLocation) {
        guard location.id != "current-location" else { return }
        withAnimation {
            savedLocations.removeAll { $0.id == location.id }
            if selectedLocationID == location.id {
                selectedLocationID = SavedLocation.currentLocation.id
            }
        }
        onLocationsChanged(savedLocations)
        HapticEngine.shared.medium()
    }
}

// MARK: - Location Card

private struct LocationCard: View {
    let location: SavedLocation
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showDelete = false

    var body: some View {
        ZStack {
            // Delete background
            if showDelete {
                HStack {
                    Spacer()
                    Button {
                        HapticEngine.shared.medium()
                        onDelete()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(Color(red: 1.0, green: 0.35, blue: 0.3), in: Circle())
                    }
                    .buttonStyle(.fullTapArea)
                    .padding(.trailing, 16)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }

            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.12))
                            .frame(width: 42, height: 42)
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.5))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(location.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if !location.address.isEmpty {
                            Text(location.address)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.45))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                            .transition(.scale.combined(with: .opacity))
                    }

                    if isEditing {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isSelected
                                ? Color(red: 0.4, green: 0.85, blue: 0.6).opacity(0.25)
                                : Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.fullTapArea)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { gesture in
                        guard !isEditing else { return }
                        if gesture.translation.width < 0 {
                            offset = max(gesture.translation.width, -60)
                        }
                    }
                    .onEnded { _ in
                        if offset < -30 {
                            withAnimation(AppTheme.cardSpring) {
                                offset = -60
                                showDelete = true
                            }
                        } else {
                            withAnimation(AppTheme.cardSpring) {
                                offset = 0
                                showDelete = false
                            }
                        }
                    }
            )
        }
    }
}

// MARK: - Modern Add Location View

private struct ModernAddLocationView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (SavedLocation) -> Void

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var searchTask: Task<Void, Never>?
    @State private var showSearchResults = false
    @State private var appears = false

    var body: some View {
        ZStack {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                if let item = selectedMapItem {
                    Marker(item.name ?? "", coordinate: item.location.coordinate)
                        .tint(Color(red: 0.4, green: 0.7, blue: 1.0))
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            VStack(spacing: 0) {
                searchHeader
                Spacer()
                if let item = selectedMapItem {
                    locationPreviewPanel(item: item)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear { appears = true }
    }

    private var searchHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.5))

                    TextField(L10n.text("settings_search_location"), text: $searchText)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .onChange(of: searchText) { _, newValue in
                            searchTask?.cancel()
                            guard newValue.count >= 2 else {
                                searchResults = []
                                showSearchResults = false
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
                            showSearchResults = false
                            selectedMapItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button(L10n.text("settings_cancel")) {
                    dismiss()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)

            if showSearchResults, !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults.prefix(5), id: \.self) { item in
                        Button {
                            selectMapItem(item)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    if let addr = item.address?.fullAddress {
                                        Text(addr)
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.white.opacity(0.5))
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.2))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.fullTapArea)

                        if item != searchResults.prefix(5).last {
                            Divider()
                                .background(Color.white.opacity(0.06))
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(AppTheme.quickEaseOut, value: showSearchResults)
    }

    private func locationPreviewPanel(item: MKMapItem) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? L10n.text("location_picker_unnamed"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let addr = item.address?.fullAddress {
                    Text(addr)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Button {
                addLocation(item)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L10n.text("location_picker_add_button"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.15, green: 0.4, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .buttonStyle(.fullTapArea)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 34)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.14).opacity(0.95),
                    Color(red: 0.04, green: 0.06, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func search() {
        guard !searchText.isEmpty else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = .address

        MKLocalSearch(request: request).start { response, _ in
            if let response {
                searchResults = response.mapItems
                withAnimation { showSearchResults = true }
            }
        }
    }

    private func selectMapItem(_ item: MKMapItem) {
        selectedMapItem = item
        searchText = ""
        searchResults = []
        showSearchResults = false

        withAnimation(AppTheme.cardSpring) {
            cameraPosition = .region(MKCoordinateRegion(
                center: item.location.coordinate,
                latitudinalMeters: 1500,
                longitudinalMeters: 1500
            ))
        }
    }

    private func addLocation(_ item: MKMapItem) {
        let location = SavedLocation(
            name: item.name ?? L10n.text("location.picker.fallback_name"),
            latitude: item.location.coordinate.latitude,
            longitude: item.location.coordinate.longitude,
            address: item.address?.fullAddress ?? ""
        )
        onAdd(location)
        HapticEngine.shared.success()
        dismiss()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("With locations") {
    LocationPickerView(
        savedLocations: .constant([
            .currentLocation,
            SavedLocation(name: "İstanbul", latitude: 41.0082, longitude: 28.9784, address: "İstanbul, Turkey"),
            SavedLocation(name: "London", latitude: 51.5074, longitude: -0.1278, address: "London, United Kingdom")
        ]),
        selectedLocationID: .constant("current-location"),
        onSelect: { _ in },
        onLocationsChanged: { _ in }
    )
}

#Preview("Empty") {
    LocationPickerView(
        savedLocations: .constant([]),
        selectedLocationID: .constant("current-location"),
        onSelect: { _ in },
        onLocationsChanged: { _ in }
    )
}
#endif
