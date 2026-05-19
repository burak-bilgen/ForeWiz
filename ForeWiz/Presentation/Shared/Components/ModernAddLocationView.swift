import SwiftUI
import MapKit

// MARK: - Modern Add Location View

struct ModernAddLocationView: View {
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
