import SwiftUI
@preconcurrency import MapKit
import CoreLocation
import OSLog
import Combine

// MARK: - Destination Picker View
struct DestinationPickerView: View {
    let recentDestinations: [RecentDestination]
    let onSelect: (CLLocationCoordinate2D, String) -> Void
    let onSelectRecent: (RecentDestination) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var searchCompleter = LocationSearchCompleter()
    @StateObject private var locationManager = DestinationLocationManager()
    @State private var searchText = ""
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedName: String = ""
    @State private var hasCenteredOnUser = false
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Search Results
                if !searchCompleter.results.isEmpty {
                    searchResultsList
                }

                // Recent Destinations
                if searchText.isEmpty && !recentDestinations.isEmpty {
                    recentDestinationsSection
                }

                // Map
                mapView
                    .layoutPriority(1)

                // Selected Location Card
                if let coordinate = selectedCoordinate {
                    selectedLocationCard(coordinate)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.text("wizpath_select_destination"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.text("wizpath_cancel")) {
                        HapticEngine.shared.light()
                        dismiss()
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedCoordinate?.latitude)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: searchCompleter.results.isEmpty)
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField(L10n.text("wizpath_search_destination"), text: $searchText)
                .font(.system(size: 16))
                .autocorrectionDisabled()
                .onSubmit {
                    searchCompleter.search(query: searchText)
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchCompleter.results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onChange(of: searchText) { _, newValue in
            searchCompleter.search(query: newValue)
        }
    }

    // MARK: - Search Results
    private var searchResultsList: some View {
        List {
            ForEach(searchCompleter.results, id: \.self) { result in
                Button {
                    selectSearchResult(result)
                    HapticEngine.shared.selectionChanged()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .frame(maxHeight: 220)
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    // MARK: - Recent Destinations
    private var recentDestinationsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.text("wizpath_recent_destinations"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recentDestinations.prefix(8), id: \.self) { recent in
                        Button {
                            onSelectRecent(recent)
                            HapticEngine.shared.medium()
                            dismiss()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                Text(recent.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 70)
                            }
                            .padding(10)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Map
    private var mapView: some View {
        Map(position: $position, selection: $searchCompleter.selectedResult) {
            UserAnnotation()

            if let coord = selectedCoordinate {
                Annotation(coordinate: coord) {
                    DestinationFlag()
                } label: {
                    Text(selectedName.isEmpty ? L10n.text("wizpath_destination") : selectedName)
                }
            }

            if let mapItem = searchCompleter.selectedMapItem {
                Marker(item: mapItem)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onChange(of: locationManager.userLocation) { _, location in
            guard let location, !hasCenteredOnUser else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
            hasCenteredOnUser = true
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }

    // MARK: - Selected Location Card

    private func selectedLocationCard(_ coordinate: CLLocationCoordinate2D) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("wizpath_selected_location"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(selectedName.isEmpty ? String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude) : selectedName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCoordinate = nil
                        selectedName = ""
                    }
                } label: {
                    Text(L10n.text("wizpath_cancel"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onSelect(coordinate, selectedName)
                    HapticEngine.shared.medium()
                    dismiss()
                } label: {
                    Text(L10n.text("wizpath_confirm_destination"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
    }

    // MARK: - Actions

    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)

        Task {
            do {
                let response = try await search.start()
                if let mapItem = response.mapItems.first {
                    let coordinate = mapItem.placemark.coordinate
                    selectedCoordinate = coordinate
                    selectedName = mapItem.name ?? result.title

                    searchCompleter.selectedMapItem = mapItem
                    searchCompleter.selectedResult = MKMapItem(placemark: .init(coordinate: coordinate))

                    withAnimation(.easeInOut(duration: 0.4)) {
                        position = .region(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                    searchText = ""
                }
            } catch {
                AppLogger.search.error("Search failed: \(error.localizedDescription)")
            }
        }
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        Task {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            do {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    selectedName = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea
                    ].compactMap { $0 }.joined(separator: ", ")
                }
            } catch {
                selectedName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
            }
        }
    }
}

// MARK: - Location Search Completer
final class LocationSearchCompleter: NSObject, ObservableObject {
    @Published var results: [MKLocalSearchCompletion] = []
    @Published var selectedResult: MKMapItem?
    @Published var selectedMapItem: MKMapItem?

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.pointOfInterestFilter = .includingAll
    }

    func search(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        completer.queryFragment = query
    }
}

extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.results = Array(completer.results.prefix(8))
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        AppLogger.search.error("Search failed: \(error.localizedDescription)")
        Task { @MainActor in
            self.results = []
        }
    }
}

// MARK: - Location Manager
@MainActor
final class DestinationLocationManager: NSObject, ObservableObject {
    @Published var userLocation: CLLocation?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}

extension DestinationLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.userLocation = locations.last
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        AppLogger.location.error("Destination picker location error: \(error.localizedDescription)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    DestinationPickerView(
        recentDestinations: [
            RecentDestination(name: "Home", latitude: 41.0082, longitude: 28.9784),
            RecentDestination(name: "Office", latitude: 41.0452, longitude: 29.0220)
        ],
        onSelect: { _, _ in },
        onSelectRecent: { _ in }
    )
}
