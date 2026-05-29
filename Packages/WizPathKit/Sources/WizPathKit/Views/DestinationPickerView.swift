import CoreLocation
import SwiftUI
@preconcurrency import MapKit

// MARK: - Destination Picker View

public struct DestinationPickerView: View {
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

    public init(recentDestinations: [RecentDestination], onSelect: @escaping (CLLocationCoordinate2D, String) -> Void, onSelectRecent: @escaping (RecentDestination) -> Void) {
        self.recentDestinations = recentDestinations
        self.onSelect = onSelect
        self.onSelectRecent = onSelectRecent
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapLayer.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar.padding(.horizontal, 16).padding(.top, 8)
                    if !searchText.isEmpty {
                        searchResultsDropdown.padding(.horizontal, 16).padding(.top, 6)
                    } else if !showConfirmationCard {
                        recentOrEmptyView.padding(.horizontal, 16).padding(.top, 6)
                    }
                    Spacer()
                }
                if showConfirmationCard, let coordinate = selectedCoordinate {
                    confirmationCard(coordinate: coordinate)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16).padding(.bottom, 40)
                }
            }
            .background(Color.black)
            .navigationTitle(WizPathKitL10n.text("wizpath_select_destination"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { HapticEngine.shared.light(); dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundStyle(.white.opacity(0.7)).symbolRenderingMode(.hierarchical)
                    }.contentShape(Rectangle()).buttonStyle(.plain)
                }
            }
            .animation(AppTheme.cardSpring, value: showConfirmationCard)
            .animation(AppTheme.cardSpring, value: searchCompleter.results.isEmpty)
            .onChange(of: locationManager.userLocation) { _, location in
                guard let location else { return }
                searchCompleter.setRegion(center: location.coordinate)
                if isFirstAppearance {
                    withAnimation(AppTheme.slowEaseOut) { position = .region(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))) }
                    isFirstAppearance = false
                }
            }
            .onAppear { locationManager.requestLocation() }
        }
    }

    private var mapLayer: some View {
        Map(position: $position, selection: $searchCompleter.selectedResult) {
            UserAnnotation()
            if let coord = selectedCoordinate {
                Annotation(coordinate: coord) { DestinationFlag() } label: {
                    Text(selectedName.isEmpty ? WizPathKitL10n.text("wizpath_destination") : selectedName).font(.system(size: 11, weight: .semibold))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls { MapUserLocationButton(); MapCompass() }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                TextField(WizPathKitL10n.text("wizpath_search_destination"), text: $searchText).font(.system(size: 15)).autocorrectionDisabled().textInputAutocapitalization(.never).submitLabel(.search).onSubmit { searchCompleter.search(query: searchText) }
                if searchCompleter.isSearching && !searchText.isEmpty { ProgressView().scaleEffect(0.7).tint(.secondary) }
                if !searchText.isEmpty {
                    Button { searchText = ""; searchCompleter.clearResults(); selectedCoordinate = nil; showConfirmationCard = false } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundStyle(.tertiary)
                    }.contentShape(Rectangle()).buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.regularMaterial).environment(\.colorScheme, .dark).overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.5)))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            .onChange(of: searchText) { _, newValue in searchCompleter.search(query: newValue) }
        }
    }

    private var searchResultsDropdown: some View {
        Group {
            if searchCompleter.results.isEmpty && !searchCompleter.isSearching && searchText.count >= 2 {
                VStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").font(.system(size: 22)).foregroundStyle(.secondary.opacity(0.5))
                    Text(WizPathKitL10n.text("wizpath_no_results")).font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity).padding(.vertical, 20).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else if !searchCompleter.results.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchCompleter.results, id: \.self) { result in
                            Button { selectSearchResult(result); HapticEngine.shared.selectionChanged() } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.liquidAccent.opacity(0.1)).frame(width: 32, height: 32)
                                        Image(systemName: iconForResult(result)).font(.system(size: 13)).foregroundStyle(Color.liquidAccent)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(result.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                                        if !result.subtitle.isEmpty { Text(result.subtitle).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1) }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary)
                                }.padding(.horizontal, 14).padding(.vertical, 10)
                            }.contentShape(Rectangle()).buttonStyle(.plain)
                            if result != searchCompleter.results.last { Divider().overlay(Color.white.opacity(0.06)).padding(.leading, 58) }
                        }
                    }
                }
                .scrollContentBackground(.hidden).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 6).frame(maxHeight: 280)
            }
        }
    }

    private var recentOrEmptyView: some View {
        Group {
            if !recentDestinations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(WizPathKitL10n.text("wizpath_recent_destinations")).font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary).padding(.horizontal, 4)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(recentDestinations.prefix(5).enumerated()), id: \.offset) { _, recent in
                                Button { onSelectRecent(recent); HapticEngine.shared.medium(); dismiss() } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.arrow.circlepath").font(.system(size: 10))
                                        Text(recent.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                    }.foregroundStyle(.white.opacity(0.8)).padding(.horizontal, 12).padding(.vertical, 7).background(.white.opacity(0.06), in: Capsule())
                                        .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 0.5))
                                }.contentShape(Rectangle()).buttonStyle(.plain)
                            }
                        }
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill").font(.system(size: 14)).foregroundStyle(Color.liquidAccent.opacity(0.4))
                    Text(WizPathKitL10n.text("wizpath_search_hint_subtitle")).font(.system(size: 12)).foregroundStyle(.secondary)
                }.padding(.vertical, 12).padding(.horizontal, 14).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func confirmationCard(coordinate: CLLocationCoordinate2D) -> some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(Color.liquidAccent.opacity(0.12)).frame(width: 36, height: 36); Image(systemName: "mappin.and.ellipse").font(.system(size: 16)).foregroundStyle(Color.liquidAccent) }
            VStack(alignment: .leading, spacing: 1) {
                Text(WizPathKitL10n.text("wizpath_selected_location")).font(.system(size: 9, weight: .semibold)).foregroundStyle(.tertiary)
                Text(selectedName).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
            }
            Spacer(minLength: 8)
            Button {
                onSelect(coordinate, selectedName); HapticEngine.shared.medium(); dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 14))
                    Text(WizPathKitL10n.text("wizpath_confirm_destination")).font(.system(size: 13, weight: .semibold))
                }.foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 9)
                    .background(LinearGradient(colors: [Color.liquidAccent, Color.liquidAccentSoft], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Capsule()).shadow(color: .liquidAccent.opacity(0.3), radius: 8, y: 3)
            }.contentShape(Rectangle()).buttonStyle(.plain)
            Button { withAnimation(AppTheme.pressSpring) { selectedCoordinate = nil; selectedName = ""; showConfirmationCard = false } } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(.tertiary)
            }.contentShape(Rectangle()).buttonStyle(.plain)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial).environment(\.colorScheme, .dark).overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.5)))
        .shadow(color: .black.opacity(0.25), radius: 20, y: -6)
    }

    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        Task {
            do {
                // Wait for a rate-limit slot (shared across all PlaceRequest types)
                await PlaceRequestThrottler.shared.waitForSlot()
                let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MKLocalSearch.Response, any Error>) in
                    search.start { response, error in
                        if let response = response {
                            continuation.resume(returning: response)
                            return
                        }
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(throwing: URLError(.unknown))
                        }
                    }
                }
                if let mapItem = response.mapItems.first {
                    let coordinate = mapItem.placemark.coordinate
                    selectedCoordinate = coordinate
                    selectedName = mapItem.name ?? result.title
                    searchCompleter.selectedResult = MKMapItem(placemark: .init(coordinate: coordinate))
                    searchText = ""; searchCompleter.clearResults()
                    withAnimation(AppTheme.cardSpring) { showConfirmationCard = true }
                    withAnimation(AppTheme.defaultEaseOut) { position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))) }
                }
            } catch { AppLogger.search.error("Search failed: \(error.localizedDescription)") }
        }
    }

    private func iconForResult(_ result: MKLocalSearchCompletion) -> String {
        let subtitle = result.subtitle.lowercased()
        if subtitle.contains("restaurant") || subtitle.contains("cafe") || subtitle.contains("food") { return "fork.knife" }
        if subtitle.contains("park") || subtitle.contains("nature") { return "leaf.fill" }
        if subtitle.contains("school") || subtitle.contains("university") { return "book.fill" }
        if subtitle.contains("hospital") || subtitle.contains("clinic") { return "cross.fill" }
        if subtitle.contains("station") || subtitle.contains("airport") || subtitle.contains("transit") { return "tram.fill" }
        if subtitle.contains("store") || subtitle.contains("shop") || subtitle.contains("mall") { return "bag.fill" }
        return "mappin.circle.fill"
    }
}
