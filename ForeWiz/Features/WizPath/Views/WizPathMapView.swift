import SwiftUI
@preconcurrency import MapKit
import CoreLocation

// MARK: - WizPath Map View (iOS 17+ MapKit)
struct WizPathMapView: View {
    @ObservedObject var viewModel: WizPathViewModel
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedAnnotation: MKMapItem?

    var body: some View {
        Map(position: $position, selection: $selectedAnnotation) {
            // User location
            UserAnnotation()

            // Route overlay
            if let route = viewModel.currentRoute, viewModel.isShowingRoute {
                let coords = route.routeCoordinates
                if coords.count > 1 {
                    // Main route polyline
                    MapPolyline(coordinates: coords)
                        .stroke(routeColor(for: route), lineWidth: 3)

                }

                // Destination marker
                Annotation(coordinate: route.destination) {
                    DestinationFlag()
                } label: {
                    Text(L10n.text("wizpath_destination"))
                        .font(.system(size: 11, weight: .semibold))
                }

                // Weather change point markers (max 6)
                let changePoints = Array(route.weatherChangePoints.prefix(6))
                ForEach(changePoints) { segment in
                    if let weather = segment.weather {
                        Annotation(coordinate: segment.coordinate) {
                            WeatherMarker(weather: weather, eta: segment.etaShortDisplay)
                        } label: {
                            Text(segment.etaShortDisplay)
                        }
                    }
                }
            }

            // Origin marker when route exists
            if let origin = viewModel.originCoordinate, viewModel.currentRoute != nil {
                Annotation(coordinate: origin) {
                    OriginMarker()
                } label: {
                    Text(L10n.text("wizpath_start"))
                        .font(.system(size: 11, weight: .semibold))
                }
            }

            // Destination preview when no route yet
            if let dest = viewModel.destinationCoordinate, viewModel.currentRoute == nil {
                Annotation(coordinate: dest) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.red)
                        .background(Circle().fill(.white).frame(width: 22, height: 22))
                } label: {
                    Text(viewModel.destinationName)
                        .font(.system(size: 11, weight: .semibold))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onChange(of: viewModel.currentRoute) { _, route in
            if let r = route {
                withAnimation(.easeInOut(duration: 0.6)) {
                    position = .region(routeRegion(r))
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            mapControlsOverlay
                .padding(10)
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.currentRoute != nil {
                toggleRouteButton
                    .padding(10)
            }
        }
        .onAppear {
            // Center on user location initially
            if let origin = viewModel.originCoordinate, viewModel.currentRoute == nil {
                position = .region(MKCoordinateRegion(
                    center: origin,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

// MARK: - Map Controls Overlay
    private var mapControlsOverlay: some View {
        VStack(spacing: 6) {
            if viewModel.currentRoute != nil {
                legendControl
            }
        }
    }

    private var legendControl: some View {
        VStack(alignment: .leading, spacing: 3) {
            legendRow(color: .green, label: L10n.text("wizpath_weather_good"))
            legendRow(color: .orange, label: L10n.text("wizpath_weather_caution"))
            legendRow(color: .red, label: L10n.text("wizpath_weather_severe"))
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .font(.system(size: 10, weight: .medium))
    }

    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    private var toggleRouteButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.isShowingRoute.toggle()
            }
            HapticEngine.shared.light()
        } label: {
            Image(systemName: viewModel.isShowingRoute ? "eye.fill" : "eye.slash.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private func routeColor(for route: WizPathRoute) -> Color {
        switch route.overallRisk {
        case .good: return .green
        case .caution: return .orange
        case .severe: return .red
        }
    }

    private func routeRegion(_ route: WizPathRoute) -> MKCoordinateRegion {
        let coords = route.routeCoordinates
        guard !coords.isEmpty else {
            return MKCoordinateRegion(
                center: route.destination,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for c in coords {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Origin Marker
struct OriginMarker: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(pulse ? 0.3 : 0.15))
                .frame(width: pulse ? 40 : 30, height: pulse ? 40 : 30)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)

            Image(systemName: "location.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .background(Circle().fill(.blue).frame(width: 20, height: 20))
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Destination Flag
struct DestinationFlag: View {
    @State private var bounce = false

    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 32))
            .foregroundStyle(.red)
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

// MARK: - Weather Marker
struct WeatherMarker: View {
    let weather: SegmentWeather
    let eta: String

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color(hex: weather.severity.colorHex).opacity(0.2))
                    .frame(width: isVisible ? 36 : 24, height: isVisible ? 36 : 24)

                Image(systemName: weather.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: weather.severity.colorHex))
                    .shadow(color: Color(hex: weather.severity.colorHex).opacity(0.5), radius: 3)
            }

            Text(eta)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
        }
        .scaleEffect(isVisible ? 1 : 0.5)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - WizPathSegment + ETA Short Display
extension WizPathSegment {
    var etaShortDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: estimatedArrival)
    }
}

// MARK: - Preview
#Preview {
    WizPathMapView(viewModel: WizPathViewModel())
        .frame(height: 300)
}
