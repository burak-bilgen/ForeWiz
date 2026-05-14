import SwiftUI
@preconcurrency import MapKit
import CoreLocation
import Combine
import OSLog

// MARK: - WizPath Map View
struct WizPathMapView: View {
    @ObservedObject var viewModel: WizPathViewModel
    @StateObject private var locationManager = WizPathLocationManager()
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7563, longitude: 29.8303),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var routePolyline: MKPolyline?
    @State private var weatherAnnotations: [WeatherAnnotation] = []
    @State private var hasCenteredOnUser = false
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $mapRegion,
                showsUserLocation: true,
                annotationItems: weatherAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    WeatherMapMarker(annotation: annotation)
                }
            }
            .overlay(
                RouteOverlayView(route: viewModel.currentRoute)
            )
            .onChange(of: viewModel.currentRoute) { newRoute in
                if let route = newRoute {
                    updateMapWithRoute(route)
                }
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
            
            // Map Controls
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    MapControlsView(
                        onRecenter: { recenterOnUserLocation() },
                        onTrafficToggle: { toggleTraffic() }
                    )
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func updateMapWithRoute(_ route: WizPathRoute) {
        // Update region to fit route
        if let polyline = route.polyline {
            let rect = polyline.boundingMapRect
            let region = MKCoordinateRegion(rect)
            withAnimation(.easeOut(duration: 0.5)) {
                mapRegion = region
            }
        }
        
        // Create weather annotations for change points
        weatherAnnotations = route.weatherChangePoints.map { segment in
            WeatherAnnotation(
                id: segment.id,
                coordinate: segment.coordinate,
                weather: segment.weather,
                eta: segment.etaDisplay
            )
        }
    }
    
    private func recenterOnUserLocation() {
        if let userLocation = locationManager.userLocation {
            withAnimation(.easeOut(duration: 0.5)) {
                mapRegion.center = userLocation.coordinate
            }
        } else if let route = viewModel.currentRoute,
                  let polyline = route.polyline {
            let rect = polyline.boundingMapRect
            let region = MKCoordinateRegion(rect)
            withAnimation(.easeOut(duration: 0.5)) {
                mapRegion = region
            }
        }
    }
    
    private func toggleTraffic() {
        viewModel.showTraffic.toggle()
    }
}

// MARK: - Location Manager for Map
@MainActor
final class WizPathLocationManager: NSObject, ObservableObject {
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
    
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
}

extension WizPathLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                self.userLocation = location
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        AppLogger.location.error("Location manager error: \(error)")
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

// MARK: - Route Overlay View
struct RouteOverlayView: View {
    let route: WizPathRoute?
    
    var body: some View {
        GeometryReader { geometry in
            if let route = route,
               let polyline = route.polyline {
                RoutePolylineShape(
                    polyline: polyline,
                    segments: route.segments,
                    riskColor: Color(hex: route.overallRisk.color)
                )
                .stroke(
                    routeRiskGradient(for: route),
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
    }
    
    private func routeRiskGradient(for route: WizPathRoute) -> LinearGradient {
        // Create gradient based on weather severity along the route
        let colors = route.segments.compactMap { segment in
            segment.weather?.severity.color
        }
        
        if colors.isEmpty {
            return LinearGradient(
                colors: [Color(red: 0.0, green: 1.0, blue: 0.25)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Route Polyline Shape
struct RoutePolylineShape: Shape {
    let polyline: MKPolyline
    let segments: [WizPathSegment]
    let riskColor: Color
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points = polyline.points()
        let pointCount = polyline.pointCount
        
        guard pointCount > 0 else { return path }
        
        // Convert MKMapPoint to local coordinates (simplified)
        // In production, use proper map projection
        let firstPoint = CGPoint(
            x: CGFloat(points[0].x),
            y: CGFloat(points[0].y)
        )
        path.move(to: firstPoint)
        
        for i in 1..<pointCount {
            let point = CGPoint(
                x: CGFloat(points[i].x),
                y: CGFloat(points[i].y)
            )
            path.addLine(to: point)
        }
        
        return path
    }
}

// MARK: - Weather Annotation
struct WeatherAnnotation: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let weather: SegmentWeather?
    let eta: String
}

// MARK: - Weather Map Marker
struct WeatherMapMarker: View {
    let annotation: WeatherAnnotation
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Weather Icon
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 36, height: 36)
                
                if let weather = annotation.weather {
                    Image(systemName: weather.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(weather.severity.color)
                        .shadow(color: weather.severity.color.opacity(0.8), radius: 4)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                }
            }
            
            // ETA Label
            Text(annotation.eta)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.black.opacity(0.7))
                )
            
            // Tooltip on hover
            if isHovered, let weather = annotation.weather {
                WeatherTooltip(weather: weather)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isHovered.toggle()
            }
        }
    }
}

// MARK: - Weather Tooltip
struct WeatherTooltip: View {
    let weather: SegmentWeather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: weather.iconName)
                    .foregroundStyle(weather.severity.color)
                Text("\(Int(weather.temperature))°C")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            if weather.precipitationChance > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                    Text("\(Int(weather.precipitationChance * 100))%")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            
            if weather.windSpeed > 20 {
                HStack(spacing: 4) {
                    Image(systemName: "wind")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.orange)
                    Text("\(Int(weather.windSpeed)) km/h")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.orange)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(weather.severity.color.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Map Controls View
struct MapControlsView: View {
    let onRecenter: () -> Void
    let onTrafficToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Recenter Button
            MapControlButton(
                icon: "location.fill",
                action: onRecenter,
                accentColor: Color(red: 0.0, green: 1.0, blue: 0.25)
            )
            
            // Traffic Toggle
            MapControlButton(
                icon: "car.fill",
                action: onTrafficToggle,
                accentColor: Color.orange
            )
        }
    }
}

// MARK: - Map Control Button
struct MapControlButton: View {
    let icon: String
    let action: () -> Void
    let accentColor: Color
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.8))
                )
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Destination Marker View
struct DestinationMarkerView: View {
    let title: String
    let eta: String
    let risk: RouteRisk
    
    var body: some View {
        VStack(spacing: 4) {
            // Destination Pin
            ZStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: risk.color))
                
                Image(systemName: "flag.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .offset(y: -2)
            }
            
            // Arrival Info Card
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                Text("ETA: \(eta)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: risk.color))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(hex: risk.color).opacity(0.5), lineWidth: 1)
            )
        }
    }
}

// MARK: - WizPath View Model Extension
extension WizPathViewModel {
    var showTraffic: Bool {
        get { UserDefaults.standard.bool(forKey: "wizpath_show_traffic") }
        set { UserDefaults.standard.set(newValue, forKey: "wizpath_show_traffic") }
    }
}
