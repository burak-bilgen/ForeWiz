import Combine
import Foundation
@preconcurrency import MapKit

// MARK: - Location Search Completer

@MainActor
public final class LocationSearchCompleter: NSObject, ObservableObject {
    @Published public var results: [MKLocalSearchCompletion] = []
    @Published public var selectedResult: MKMapItem?
    @Published public var isSearching = false

    private let completer = MKLocalSearchCompleter()
    private var searchTask: Task<Void, Never>?
    private var hasSetRegion = false

    override public init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.pointOfInterestFilter = .includingAll
    }

    public func setRegion(center: CLLocationCoordinate2D) {
        guard !hasSetRegion else { return }
        hasSetRegion = true
        completer.region = MKCoordinateRegion(center: center, latitudinalMeters: 50_000, longitudinalMeters: 50_000)
    }

    public func search(query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else { results = []; isSearching = false; return }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            isSearching = true
            completer.queryFragment = query
        }
    }

    public func clearResults() { results = []; isSearching = false }
}

extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {
    nonisolated public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in self.results = Array(completer.results.prefix(10)); self.isSearching = false }
    }

    nonisolated public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in self.results = []; self.isSearching = false }
    }
}
