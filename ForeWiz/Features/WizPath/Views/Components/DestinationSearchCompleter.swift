import Combine
import Foundation
@preconcurrency import MapKit
import OSLog

// MARK: - Location Search Completer

@MainActor
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
            results = []
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            isSearching = true
            completer.queryFragment = query
        }
    }

    func clearResults() {
        results = []
        isSearching = false
    }
}

extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = Array(completer.results.prefix(10))
        isSearching = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        AppLogger.search.error("Search completer failed: \(error.localizedDescription)")
        results = []
        isSearching = false
    }
}
