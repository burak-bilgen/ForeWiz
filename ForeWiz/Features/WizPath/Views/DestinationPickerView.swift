import SwiftUI
@preconcurrency import MapKit
import CoreLocation
import OSLog
import Combine

// MARK: - Destination Picker View
struct DestinationPickerView: View {
    let onSelect: (CLLocation, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @StateObject private var locationManager = DestinationLocationManager()
    @State private var searchText = ""
    // Default to Derince, Kocaeli, Türkiye (not San Francisco) - will update to user location
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7563, longitude: 29.8303),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedName: String = ""
    @State private var showConfirmButton = false
    @State private var hasCenteredOnUser = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(
                    text: $searchText,
                    placeholder: L10n.text("wizpath_search_destination")
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .onChange(of: searchText) { newValue in
                    searchCompleter.search(query: newValue)
                }
                
                // Search Results
                if !searchCompleter.results.isEmpty {
                    SearchResultsList(
                        results: searchCompleter.results,
                        onSelect: { result in
                            selectSearchResult(result)
                        }
                    )
                    .background(Color.black.opacity(0.9))
                    .zIndex(1)
                }
                
                // Map
                Map(coordinateRegion: $mapRegion,
                    showsUserLocation: true
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onTapGesture { location in
                    // Handle map tap to select coordinate
                    handleMapTap(at: location)
                }
                .onChange(of: locationManager.userLocation) { location in
                    if let location = location, !hasCenteredOnUser {
                        // Center on user's actual location when first available
                        withAnimation(.easeOut(duration: 0.5)) {
                            mapRegion.center = location.coordinate
                        }
                        hasCenteredOnUser = true
                    }
                }
                .onAppear {
                    locationManager.requestLocation()
                }
                
                // Selected Location Info
                if let coordinate = selectedCoordinate {
                    SelectedLocationCard(
                        coordinate: coordinate,
                        onConfirm: {
                            confirmSelection(coordinate)
                        },
                        onCancel: {
                            selectedCoordinate = nil
                            showConfirmButton = false
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle(L10n.text("wizpath_select_destination"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.text("cancel")) {
                    dismiss()
                }
                .foregroundStyle(Color(red: 0.0, green: 1.0, blue: 0.25))
            }
        }
    }
    
    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        Task {
            do {
                let response = try await search.start()
                if let mapItem = response.mapItems.first {
                    let coordinate = mapItem.placemark.coordinate
                    selectedCoordinate = coordinate
                    selectedName = result.title  // Use search result title as name
                    
                    // Center map on selection
                    withAnimation {
                        mapRegion.center = coordinate
                    }
                    showConfirmButton = true
                }
            } catch {
                AppLogger.search.error("Failed to get location: \(error)")
            }
        }
    }
    
    private func handleMapTap(at location: CGPoint) {
        // Convert tap point to coordinate (simplified)
        selectedCoordinate = mapRegion.center
        
        // Geocode to get name
        Task {
            let coordinate = mapRegion.center
            do {
                let name = try await GeocodingHelper.shared.reverseGeocode(coordinate: coordinate)
                selectedName = name
            } catch {
                selectedName = "\(coordinate.latitude), \(coordinate.longitude)"
            }
        }
        
        showConfirmButton = true
    }
    
    private func confirmSelection(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let name = selectedName.isEmpty ? "\(coordinate.latitude), \(coordinate.longitude)" : selectedName
        onSelect(location, name)
        dismiss()
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.0, green: 1.0, blue: 0.25).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Search Results List
struct SearchResultsList: View {
    let results: [MKLocalSearchCompletion]
    let onSelect: (MKLocalSearchCompletion) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(results, id: \.hashValue) { result in
                    SearchResultRow(result: result, onTap: {
                        onSelect(result)
                    })
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .frame(maxHeight: 250)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.95))
        )
        .padding(.horizontal, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: MKLocalSearchCompletion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(red: 0.0, green: 1.0, blue: 0.25))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Location Card
struct SelectedLocationCard: View {
    let coordinate: CLLocationCoordinate2D
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("wizpath_selected_location"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                    
                    Text(String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .fontDesign(.monospaced)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text(L10n.text("cancel"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: onConfirm) {
                    Text(L10n.text("wizpath_confirm_destination"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0.0, green: 1.0, blue: 0.25))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.0, green: 1.0, blue: 0.25).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Location Search Completer
final class LocationSearchCompleter: NSObject, ObservableObject {
    @Published var results: [MKLocalSearchCompletion] = []
    
    private let completer = MKLocalSearchCompleter()
    private var cancellable: AnyCancellable?
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
    
    func search(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        
        completer.queryFragment = query
    }
    
    deinit {
        cancellable?.cancel()
    }
}

// MARK: - Location Manager for Destination Picker
@MainActor
final class DestinationLocationManager: NSObject, ObservableObject {
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        let status = manager.authorizationStatus
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            // Location denied - will use fallback
            break
        @unknown default:
            break
        }
    }
}

extension DestinationLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                self.userLocation = location
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        AppLogger.location.error("Destination picker location error: \(error)")
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}

// MARK: - MKLocalSearchCompleter Delegate
extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        AppLogger.search.error("Search failed: \(error)")
        DispatchQueue.main.async {
            self.results = []
        }
    }
}
