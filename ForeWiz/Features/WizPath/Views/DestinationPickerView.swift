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
    @State private var isFirstAppearance = true
    @State private var showConfirmationCard = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background Map
                mapLayer
                    .ignoresSafeArea(edges: [.bottom])

                // Overlay content
                VStack(spacing: 0) {
                    searchSection
                        .padding(.top, 8)

                    Spacer()

                    if showConfirmationCard, let coordinate = selectedCoordinate {
                        confirmationCard(coordinate: coordinate)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .background(Color.black)
            .navigationTitle(L10n.text("wizpath_select_destination"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticEngine.shared.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.7))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showConfirmationCard)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: searchCompleter.results.isEmpty)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: searchCompleter.isSearching)
            .onChange(of: locationManager.userLocation) { _, location in
                guard let location else { return }
                searchCompleter.setRegion(center: location.coordinate)

                if isFirstAppearance {
                    withAnimation(.easeOut(duration: 0.6)) {
                        position = .region(MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        ))
                    }
                    isFirstAppearance = false
                }
            }
            .onAppear {
                locationManager.requestLocation()
            }
        }
    }

    // MARK: - Map Layer
    private var mapLayer: some View {
        Map(position: $position, selection: $searchCompleter.selectedResult) {
            UserAnnotation()

            if let coord = selectedCoordinate {
                Annotation(coordinate: coord) {
                    DestinationFlag()
                } label: {
                    Text(selectedName.isEmpty ? L10n.text("wizpath_destination") : selectedName)
                        .font(.system(size: 11, weight: .semibold))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 6) {
            // Search Bar
            searchBar
                .padding(.horizontal, 16)

            if !searchText.isEmpty {
                searchResultsView
            } else if showConfirmationCard {
                EmptyView()
            } else {
                recentDestinationsView
            }
        }
    }

    // MARK: - Liquid Glass Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField(L10n.text("wizpath_search_destination"), text: $searchText)
                    .font(.system(size: 16))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit {
                        searchCompleter.search(query: searchText)
                    }

                if searchCompleter.isSearching && !searchText.isEmpty {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.secondary)
                }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchCompleter.clearResults()
                        selectedCoordinate = nil
                        showConfirmationCard = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.regularMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            .onChange(of: searchText) { _, newValue in
                searchCompleter.search(query: newValue)
            }
        }
    }

    // MARK: - Search Results (Liquid Glass)
    private var searchResultsView: some View {
        Group {
            if searchCompleter.results.isEmpty && !searchCompleter.isSearching && searchText.count >= 2 {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text(L10n.text("wizpath_no_results"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
            } else if !searchCompleter.results.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchCompleter.results, id: \.self) { result in
                            Button {
                                selectSearchResult(result)
                                HapticEngine.shared.selectionChanged()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.liquidAccent.opacity(0.1))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: iconForResult(result))
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.liquidAccent)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                            if result != searchCompleter.results.last {
                                Divider()
                                    .overlay(Color.white.opacity(0.06))
                                    .padding(.leading, 66)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
                .padding(.horizontal, 16)
                .frame(maxHeight: 320)
            }
        }
    }

    // MARK: - Recent Destinations (Liquid Glass)
    private var recentDestinationsView: some View {
        Group {
            if !recentDestinations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(L10n.text("wizpath_recent_destinations"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(recentDestinations.prefix(5).enumerated()), id: \.offset) { _, recent in
                            Button {
                                onSelectRecent(recent)
                                HapticEngine.shared.medium()
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(recent.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                        Text(String(format: "%.2f, %.2f", recent.latitude, recent.longitude))
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            if recent != recentDestinations.prefix(5).last {
                                Divider()
                                    .overlay(Color.white.opacity(0.06))
                                    .padding(.leading, 66)
                            }
                        }
                    }
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                    .padding(.horizontal, 16)
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.liquidAccent.opacity(0.3))

                    VStack(spacing: 4) {
                        Text(L10n.text("wizpath_search_hint_title"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(L10n.text("wizpath_search_hint_subtitle"))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Confirmation Card (Liquid Glass)
    private func confirmationCard(coordinate: CLLocationCoordinate2D) -> some View {
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 20) {
            VStack(spacing: 16) {
                // Location Info
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.liquidAccent.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.liquidAccent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.text("wizpath_selected_location"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(selectedName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }

                    Spacer()
                }

                // Action Buttons
                HStack(spacing: 12) {
                    LiquidGlassButton(
                        L10n.text("wizpath_cancel"),
                        icon: "xmark",
                        style: .secondary,
                        haptic: .light
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCoordinate = nil
                            selectedName = ""
                            showConfirmationCard = false
                        }
                    }

                    LiquidGlassButton(
                        L10n.text("wizpath_confirm_destination"),
                        icon: "checkmark",
                        style: .primary,
                        haptic: .medium
                    ) {
                        onSelect(coordinate, selectedName)
                        dismiss()
                    }
                }
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 24, y: -8)
        .padding(.horizontal, 16)
        .padding(.bottom, 34)
    }

    // MARK: - Actions
    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)

        Task {
            do {
                let response = try await withCheckedThrowingContinuation { continuation in
                    search.start { response, error in
                        if let response = response {
                            continuation.resume(returning: response)
                        } else {
                            continuation.resume(throwing: error ?? URLError(.unknown))
                        }
                    }
                }
                if let mapItem = response.mapItems.first {
                    let coordinate = mapItem.placemark.coordinate
                    selectedCoordinate = coordinate
                    selectedName = mapItem.name ?? result.title

                    searchCompleter.selectedResult = MKMapItem(placemark: .init(coordinate: coordinate))

                    searchText = ""
                    searchCompleter.clearResults()

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showConfirmationCard = true
                    }

                    withAnimation(.easeInOut(duration: 0.5)) {
                        position = .region(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }
            } catch {
                AppLogger.search.error("Search failed: \(error.localizedDescription)")
            }
        }
    }

    private func iconForResult(_ result: MKLocalSearchCompletion) -> String {
        let subtitle = result.subtitle.lowercased()
        if subtitle.contains("restaurant") || subtitle.contains("cafe") || subtitle.contains("food") {
            return "fork.knife"
        } else if subtitle.contains("park") || subtitle.contains("nature") {
            return "leaf.fill"
        } else if subtitle.contains("school") || subtitle.contains("university") {
            return "book.fill"
        } else if subtitle.contains("hospital") || subtitle.contains("clinic") {
            return "cross.fill"
        } else if subtitle.contains("station") || subtitle.contains("airport") || subtitle.contains("transit") {
            return "tram.fill"
        } else if subtitle.contains("store") || subtitle.contains("shop") || subtitle.contains("mall") {
            return "bag.fill"
        } else {
            return "mappin.circle.fill"
        }
    }
}

// MARK: - Location Search Completer
final class LocationSearchCompleter: NSObject, ObservableObject {
    @Published var results: [MKLocalSearchCompletion] = []
    @Published var selectedResult: MKMapItem?
    @Published var isSearching = false

    private let completer = MKLocalSearchCompleter()
    private var searchTask: Task<Void, Never>?
    private var hasSetRegion = false

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.pointOfInterestFilter = .includingAll
    }

    func setRegion(center: CLLocationCoordinate2D) {
        guard !hasSetRegion else { return }
        hasSetRegion = true
        completer.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: 50_000,
            longitudinalMeters: 50_000
        )
    }

    func search(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            Task { @MainActor in
                results = []
                isSearching = false
            }
            return
        }

        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            isSearching = true
            completer.queryFragment = query
        }
    }

    func clearResults() {
        Task { @MainActor in
            results = []
            isSearching = false
        }
    }
}

extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.results = Array(completer.results.prefix(10))
            self.isSearching = false
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        AppLogger.search.error("Search completer failed: \(error.localizedDescription)")
        Task { @MainActor in
            self.results = []
            self.isSearching = false
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

// MARK: - Destination Flag
struct DestinationFlag: View {
    @State private var bounce = false

    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 32))
            .foregroundStyle(Color.coral)
            .background(
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
            )
            .scaleEffect(bounce ? 1.15 : 1.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5).repeatForever(autoreverses: true)) {
                    bounce = true
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
