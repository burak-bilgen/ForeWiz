import SwiftUI
@preconcurrency import MapKit
import CoreLocation

// MARK: - WizPath Map View
struct WizPathMapView: View {
    @Bindable var viewModel: WizPathViewModel
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedAnnotation: MKMapItem?

    var body: some View {
        Map(position: $position, selection: $selectedAnnotation) {
            UserAnnotation()

            // Route polyline
            if let route = viewModel.currentRoute, viewModel.isShowingRoute {
                let coords = route.routeCoordinates
                if coords.count > 1 {
                    MapPolyline(coordinates: coords)
                        .stroke(Color.routeRiskColor(route.overallRisk), lineWidth: 2.5)
                }

                // Destination annotation
                Annotation(coordinate: route.destination) {
                    DestinationFlag()
                } label: {
                    Text(L10n.text("wizpath_destination"))
                        .font(.system(size: 10, weight: .semibold))
                }

                // Weather change points
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

            // Origin annotation
            if let origin = viewModel.originCoordinate, viewModel.currentRoute != nil {
                Annotation(coordinate: origin) {
                    OriginMarker()
                } label: {
                    Text(L10n.text("wizpath_start"))
                        .font(.system(size: 10, weight: .semibold))
                }
            }

            // Destination pin (no route yet)
            if let dest = viewModel.destinationCoordinate, viewModel.currentRoute == nil {
                Annotation(coordinate: dest) {
                    DestinationFlag()
                } label: {
                    Text(viewModel.destinationName)
                        .font(.system(size: 10, weight: .semibold))
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
                withAnimation(AppTheme.slowEaseOut) {
                    position = .region(routeRegion(r))
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.currentRoute != nil {
                legendOverlay
                    .padding(8)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.currentRoute != nil {
                toggleRouteButton
                    .padding(8)
            }
        }
        .onAppear {
            if let origin = viewModel.originCoordinate, viewModel.currentRoute == nil {
                position = .region(MKCoordinateRegion(
                    center: origin,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Legend Overlay

    private var legendOverlay: some View {
        VStack(alignment: .leading, spacing: 3) {
            legendRow(color: .success, label: L10n.text("wizpath_weather_good"))
            legendRow(color: .warning, label: L10n.text("wizpath_weather_caution"))
            legendRow(color: .danger, label: L10n.text("wizpath_weather_severe"))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .font(.system(size: 9, weight: .medium))
    }

    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.3), radius: 1)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Toggle Route Button

    private var toggleRouteButton: some View {
        Button {
            withAnimation(AppTheme.pressSpring) {
                viewModel.isShowingRoute.toggle()
            }
            HapticEngine.shared.light()
        } label: {
            Image(systemName: viewModel.isShowingRoute ? "eye.fill" : "eye.slash.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

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
                .fill(Color.liquidAccent.opacity(pulse ? 0.3 : 0.15))
                .frame(width: pulse ? 36 : 26, height: pulse ? 36 : 26)
                .animation(AppTheme.pulseEaseOut.repeatForever(autoreverses: true), value: pulse)

            Image(systemName: "location.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .background(Circle().fill(Color.liquidAccent).frame(width: 18, height: 18))
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Weather Marker

struct WeatherMarker: View {
    let weather: SegmentWeather
    let eta: String
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                Circle()
                    .fill(Color(hex: weather.severity.colorHex).opacity(0.2))
                    .frame(width: isVisible ? 30 : 20, height: isVisible ? 30 : 20)

                Image(systemName: weather.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: weather.severity.colorHex))
                    .shadow(color: Color(hex: weather.severity.colorHex).opacity(0.4), radius: 2)
            }

            Text(eta)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(.black.opacity(0.5))
                .clipShape(Capsule())
        }
        .scaleEffect(isVisible ? 1 : 0.5)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(AppTheme.pressSpring.delay(0.15)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WizPathMapView(viewModel: WizPathViewModel())
        .frame(height: 300)
}
