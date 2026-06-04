import SwiftUI
@preconcurrency import MapKit
import CoreLocation

// MARK: - WizPath Map View

public struct WizPathMapView: View {
    @Bindable var viewModel: WizPathViewModel
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedAnnotation: MKMapItem?
    @State private var showFullScreenMap = false

    public init(viewModel: WizPathViewModel) {
        self._viewModel = Bindable(viewModel)
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $position, selection: $selectedAnnotation) {
                UserAnnotation()
                if let route = viewModel.mapsNavigationRoute, viewModel.isShowingRoute {
                    weatherCodedPolylines(route: route)
                    trafficOverlay(route: route)

                    Annotation(coordinate: route.destination) {
                        DestinationFlag()
                    } label: {
                        Text(WizPathKitL10n.text("wizpath_destination"))
                            .font(.system(size: 10, weight: .semibold))
                    }

                    weatherChangeMarkers(route: route)

                    ForEach(viewModel.smartStops) { station in
                        Annotation(coordinate: station.coordinate) {
                            SmartStopMarker(category: station.category)
                                .onTapGesture {
                                    HapticEngine.shared.light()
                                }
                        } label: {
                            Text(station.displayTitle)
                                .font(.system(size: 8, weight: .medium))
                                .lineLimit(1)
                        }
                    }

                    ForEach(viewModel.evChargers) { station in
                        Annotation(coordinate: station.coordinate) {
                            SmartStopMarker(category: .evCharger)
                                .onTapGesture {
                                    HapticEngine.shared.light()
                                }
                        } label: {
                            Text(station.displayTitle)
                                .font(.system(size: 8, weight: .medium))
                                .lineLimit(1)
                        }
                    }

                    if let origin = viewModel.originCoordinate {
                        Annotation(coordinate: origin) {
                            OriginMarker()
                        } label: {
                            Text(WizPathKitL10n.text("wizpath_start"))
                                .font(.system(size: 10, weight: .semibold))
                        }
                    }
                }

                if let dest = viewModel.destinationCoordinate, viewModel.mapsNavigationRoute == nil {
                    Annotation(coordinate: dest) {
                        DestinationFlag()
                    } label: {
                        Text(viewModel.destinationName)
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .onChange(of: viewModel.currentRoute) { _, route in
                if let r = route {
                    withAnimation(AppTheme.slowEaseOut) { position = .region(routeRegion(r)) }
                }
            }
            .onAppear {
                if let route = viewModel.mapsNavigationRoute, viewModel.currentRoute == nil {
                    withAnimation(AppTheme.slowEaseOut) { position = .region(routeRegion(route)) }
                } else if let origin = viewModel.originCoordinate, viewModel.mapsNavigationRoute == nil {
                    position = .region(MKCoordinateRegion(
                        center: origin,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }
            .onChange(of: viewModel.didLoadInitialLocation) { _, loaded in
                guard loaded, let coord = viewModel.originCoordinate else { return }
                if let route = viewModel.mapsNavigationRoute, viewModel.currentRoute == nil {
                    withAnimation(AppTheme.slowEaseOut) { position = .region(routeRegion(route)) }
                } else if viewModel.mapsNavigationRoute == nil {
                    withAnimation(AppTheme.slowEaseOut) {
                        position = .region(MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        ))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onTapGesture {
                withAnimation(AppTheme.cardSpring) {
                    viewModel.mapExpanded.toggle()
                    HapticEngine.shared.light()
                }
            }

            // Custom map controls — always visible, no overlap with system controls
            VStack(spacing: 6) {
                userLocationButton
                if viewModel.mapsNavigationRoute != nil {
                    trafficToggleButton
                    toggleRouteButton
                    fullScreenButton
                }
            }
            .padding(.trailing, 8)
            .padding(.top, 8)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenMapView(
                viewModel: viewModel,
                position: $position,
                onDismiss: { showFullScreenMap = false }
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Map Content Builders (extracted to avoid type-checker timeout)

    @MapContentBuilder
    private func weatherCodedPolylines(route: WizPathRoute) -> some MapContent {
        RouteMapContent.weatherPolylines(route: route, lineWidth: viewModel.mapExpanded ? 4.0 : 3.0)
    }

    @MapContentBuilder
    private func trafficOverlay(route: WizPathRoute) -> some MapContent {
        RouteMapContent.trafficOverlay(
            route: route,
            lineWidth: viewModel.mapExpanded ? 7 : 5,
            showTraffic: viewModel.showTrafficOnMap,
            congestion: viewModel.currentTrafficCongestion
        )
    }

    @MapContentBuilder
    private func weatherChangeMarkers(route: WizPathRoute) -> some MapContent {
        RouteMapContent.weatherChangeMarkers(
            route: route,
            maxCount: viewModel.mapExpanded ? 12 : 6,
            placeNames: viewModel.segmentPlaceNames,
            onSelect: { segment in
                viewModel.selectedWeatherSegment = segment
                viewModel.showWeatherDetail = true
                HapticEngine.shared.light()
            }
        )
    }

    // MARK: - Control Buttons

    private var userLocationButton: some View {
        Button {
            HapticEngine.shared.light()
            if let coord = viewModel.originCoordinate {
                withAnimation(AppTheme.slowEaseOut) {
                    position = .region(MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .accessibilityLabel(WizPathKitL10n.text("wizpath_map_center_location"))
    }

    private var trafficToggleButton: some View {
        Button {
            withAnimation(AppTheme.pressSpring) {
                viewModel.showTrafficOnMap.toggle()
                HapticEngine.shared.selectionChanged()
            }
        } label: {
            Image(systemName: viewModel.showTrafficOnMap ? "car.2.fill" : "car.2")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(viewModel.showTrafficOnMap ? Color.liquidAccent : .white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Circle()
                        .stroke(viewModel.showTrafficOnMap ? Color.liquidAccent.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
                )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .accessibilityLabel(WizPathKitL10n.text("wizpath_map_traffic"))
    }

    private var toggleRouteButton: some View {
        Button {
            withAnimation(AppTheme.pressSpring) { viewModel.isShowingRoute.toggle() }
            HapticEngine.shared.light()
        } label: {
            Image(systemName: viewModel.isShowingRoute ? "eye.fill" : "eye.slash.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    private var fullScreenButton: some View {
        Button {
            HapticEngine.shared.medium()
            showFullScreenMap = true
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .accessibilityLabel(WizPathKitL10n.text("wizpath_map_fullscreen"))
    }

    // MARK: - Helpers

    private func routeRegion(_ route: WizPathRoute) -> MKCoordinateRegion {
        let coords = route.routeCoordinates
        guard !coords.isEmpty else {
            return MKCoordinateRegion(center: route.destination, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for c in coords {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Full-Screen Map Sheet

struct FullScreenMapView: View {
    @Bindable var viewModel: WizPathViewModel
    @Binding var position: MapCameraPosition
    let onDismiss: () -> Void
    @State private var showLegend = true

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $position, selection: .constant(nil)) {
                UserAnnotation()
                if let route = viewModel.mapsNavigationRoute, viewModel.isShowingRoute {
                    RouteMapContent.weatherPolylines(route: route, lineWidth: 5)
                    RouteMapContent.trafficOverlay(
                        route: route,
                        lineWidth: 9,
                        opacity: 0.35,
                        showTraffic: viewModel.showTrafficOnMap,
                        congestion: viewModel.currentTrafficCongestion
                    )

                    Annotation(coordinate: route.destination) {
                        DestinationFlag()
                    } label: {
                        Text(WizPathKitL10n.text("wizpath_destination")).font(.system(size: 10, weight: .semibold))
                    }

                    if let origin = viewModel.originCoordinate {
                        Annotation(coordinate: origin) {
                            OriginMarker()
                        } label: {
                            Text(WizPathKitL10n.text("wizpath_start")).font(.system(size: 10, weight: .semibold))
                        }
                    }

                    RouteMapContent.weatherChangeMarkers(
                        route: route,
                        maxCount: 12,
                        placeNames: viewModel.segmentPlaceNames,
                        onSelect: { segment in
                            viewModel.selectedWeatherSegment = segment
                            viewModel.showWeatherDetail = true
                            HapticEngine.shared.light()
                        }
                    )

                    ForEach(viewModel.smartStops) { station in
                        Annotation(coordinate: station.coordinate) {
                            SmartStopMarker(category: station.category)
                                .onTapGesture {
                                    HapticEngine.shared.light()
                                }
                        } label: {
                            Text(station.displayTitle).font(.system(size: 8, weight: .medium)).lineLimit(1)
                        }
                    }

                    ForEach(viewModel.evChargers) { station in
                        Annotation(coordinate: station.coordinate) {
                            SmartStopMarker(category: .evCharger)
                                .onTapGesture {
                                    HapticEngine.shared.light()
                                }
                        } label: {
                            Text(station.displayTitle).font(.system(size: 8, weight: .medium)).lineLimit(1)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls { MapUserLocationButton(); MapCompass(); MapScaleView() }

            VStack(spacing: 8) {
                Button {
                    HapticEngine.shared.light()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }
                .buttonStyle(.plain)
                .padding(12)

                Button {
                    withAnimation { viewModel.showTrafficOnMap.toggle() }
                } label: {
                    Image(systemName: viewModel.showTrafficOnMap ? "car.2.fill" : "car.2")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(viewModel.showTrafficOnMap ? Color.liquidAccent : .white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                        .shadow(color: .black.opacity(0.2), radius: 4)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showLegend.toggle() }
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                        .shadow(color: .black.opacity(0.2), radius: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(8)

            if showLegend {
                VStack(alignment: .leading, spacing: 3) {
                    Text(WizPathKitL10n.text("wizpath_weather_legend"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 2)
                    legendRow(color: Color(hex: "#34C759"), label: WizPathKitL10n.text("wizpath_weather_good"))
                    legendRow(color: Color(hex: "#FFCC00"), label: WizPathKitL10n.text("wizpath_weather_caution"))
                    legendRow(color: Color(hex: "#FF3B30"), label: WizPathKitL10n.text("wizpath_weather_severe"))
                    legendRow(color: Color(hex: "#007AFF"), label: WizPathKitL10n.text("wizpath_condition_rain"))
                    legendRow(color: Color(hex: "#AF52DE"), label: WizPathKitL10n.text("wizpath_condition_storm"))
                    if viewModel.showTrafficOnMap, viewModel.currentTrafficCongestion != .unknown {
                        let c = viewModel.currentTrafficCongestion
                        Divider().overlay(.white.opacity(0.15))
                        legendRow(color: Color(hex: c.colorHex), label: c.localizedTitle)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                .font(.system(size: 9, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .statusBarHidden()
    }

    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6).shadow(color: color.opacity(0.3), radius: 1)
            Text(label).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Shared Route Map Content Builders

/// Shared `@MapContentBuilder` helpers used by both `WizPathMapView` and `FullScreenMapView`.
/// Eliminates duplication of weather-coded polylines, traffic overlay, and weather change markers.
@MainActor
enum RouteMapContent {
    @MapContentBuilder
    static func weatherPolylines(route: WizPathRoute, lineWidth: CGFloat) -> some MapContent {
        let segs = route.segments
        if segs.count > 1 {
            ForEach(Array(segs.dropLast().enumerated()), id: \.offset) { i, seg in
                let nextSeg = segs[i + 1]
                let weather = seg.weather
                MapPolyline(coordinates: [seg.coordinate, nextSeg.coordinate])
                    .stroke(Color(hex: weather?.condition.mapRouteColor ?? "#34C759").opacity(0.85), lineWidth: lineWidth)
            }
        }
    }

    @MapContentBuilder
    static func trafficOverlay(
        route: WizPathRoute,
        lineWidth: CGFloat,
        opacity: CGFloat = 0.45,
        showTraffic: Bool,
        congestion: TrafficCongestionLevel
    ) -> some MapContent {
        if showTraffic, congestion != .unknown {
            MapPolyline(coordinates: route.routeCoordinates)
                .stroke(Color(hex: congestion.colorHex).opacity(opacity), lineWidth: lineWidth)
        }
    }

    @MapContentBuilder
    static func weatherChangeMarkers(
        route: WizPathRoute,
        maxCount: Int,
        placeNames: [UUID: String],
        onSelect: @escaping (WizPathSegment) -> Void
    ) -> some MapContent {
        let changePoints = Array(route.weatherChangePoints.prefix(maxCount))
        ForEach(changePoints) { segment in
            if let weather = segment.weather {
                let placeName = placeNames[segment.id]
                Annotation(coordinate: segment.coordinate) {
                    Button {
                        onSelect(segment)
                    } label: {
                        EnhancedWeatherMarker(weather: weather, eta: segment.etaDisplay)
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                } label: {
                    if let placeName {
                        Text(placeName)
                            .font(.system(size: 9, weight: .medium))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Weather Marker (shows condition + temp + ETA)

public struct EnhancedWeatherMarker: View {
    let weather: SegmentWeather
    let eta: String
    @State private var isVisible = false

    public init(weather: SegmentWeather, eta: String) {
        self.weather = weather
        self.eta = eta
    }

    public var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color(hex: weather.condition.mapMarkerColor).opacity(0.18))
                    .frame(width: 32, height: 32)
                Circle()
                    .stroke(Color(hex: weather.condition.mapMarkerColor).opacity(0.5), lineWidth: 1.5)
                    .frame(width: 28, height: 28)
                Image(systemName: weather.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: weather.condition.mapMarkerColor))
                    .shadow(color: Color(hex: weather.condition.mapMarkerColor).opacity(0.4), radius: 2)
            }

            Text(eta)
                .font(.system(size: 7, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.black.opacity(0.55))
                .clipShape(Capsule())

            Text(verbatim: "\u{00B0}\(Int(weather.temperature))")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    Capsule()
                        .fill(weather.temperature >= 28 ? Color.danger.opacity(0.5) :
                              weather.temperature <= 5 ? Color(hex: "#5AC8FA").opacity(0.5) :
                              .black.opacity(0.4))
                )
        }
        .scaleEffect(isVisible ? 1 : 0.5)
        .opacity(isVisible ? 1 : 0)
        .onAppear { withAnimation(AppTheme.pressSpring.delay(0.15)) { isVisible = true } }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.5)).animation(AppTheme.pressSpring),
            removal: .opacity.combined(with: .scale(scale: 0.3)).animation(AppTheme.quickEaseOut)
        ))
    }
}

// MARK: - Origin Marker

public struct OriginMarker: View {
    @State private var pulse = false
    public init() {}
    public var body: some View {
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

// MARK: - Smart Stop Marker

public struct SmartStopMarker: View {
    let category: POICategory
    @State private var isVisible = false

    public init(category: POICategory) {
        self.category = category
    }

    public var body: some View {
        let catColor = Color(hex: category.color)
        ZStack {
            Circle()
                .fill(catColor.opacity(0.2))
                .frame(width: isVisible ? 30 : 20, height: isVisible ? 30 : 20)
            Circle()
                .stroke(catColor.opacity(0.75), lineWidth: 1)
                .frame(width: isVisible ? 26 : 18, height: isVisible ? 26 : 18)
            Image(systemName: category.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(catColor)
                .shadow(color: catColor.opacity(0.4), radius: 2)
        }
        .scaleEffect(isVisible ? 1 : 0.5)
        .opacity(isVisible ? 1 : 0)
        .onAppear { withAnimation(AppTheme.pressSpring.delay(0.1)) { isVisible = true } }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.5)).animation(AppTheme.pressSpring),
            removal: .opacity.combined(with: .scale(scale: 0.3)).animation(AppTheme.quickEaseOut)
        ))
    }
}
