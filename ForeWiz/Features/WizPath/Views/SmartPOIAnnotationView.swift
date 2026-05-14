import SwiftUI
import MapKit

// MARK: - Smart POI Map Annotation View
struct SmartPOIAnnotationView: View {
    let stop: SmartStop
    @State private var isPulsing = false
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // POI Marker
            ZStack {
                // Pulse effect for safe POIs
                if stop.safetyStatus == .safe {
                    Circle()
                        .fill(Color(hex: stop.safetyStatus.color).opacity(0.3))
                        .frame(width: isPulsing ? 60 : 40, height: isPulsing ? 60 : 40)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
                        .onAppear { isPulsing = true }
                }
                
                // Main circle background
                Circle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 40, height: 40)
                
                // Safety status ring
                Circle()
                    .stroke(Color(hex: stop.safetyStatus.color), lineWidth: 2)
                    .frame(width: 40, height: 40)
                
                // POI Icon
                Image(systemName: stop.category.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: stop.category.color))
                    .shadow(color: Color(hex: stop.category.color).opacity(0.5), radius: 4)
                
                // Safety indicator dot
                Circle()
                    .fill(Color(hex: stop.safetyStatus.color))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .offset(x: 12, y: -12)
            }
            .frame(width: 60, height: 60)
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    showDetails.toggle()
                }
            }
            
            // Tooltip card
            if showDetails {
                SmartPOITooltip(stop: stop)
                    .transition(.scale.combined(with: .opacity))
                    .offset(y: -10)
            }
        }
    }
}

// MARK: - Smart POI Tooltip
struct SmartPOITooltip: View {
    let stop: SmartStop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with name and safety status
            HStack {
                Image(systemName: stop.category.iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: stop.category.color))
                
                Text(stop.displayTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // Safety badge
                Text(stop.safetyStatus.localizedTitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: stop.safetyStatus.color))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: stop.safetyStatus.color).opacity(0.15))
                    )
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // ETA and weather info
            HStack(spacing: 12) {
                // ETA
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text(stop.etaDisplay)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                if let weather = stop.weatherAtArrival {
                    // Weather condition
                    HStack(spacing: 4) {
                        Image(systemName: weather.iconName)
                            .font(.system(size: 10))
                            .foregroundStyle(weather.severity.color)
                        Text("\(Int(weather.temperature))°")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }
                    
                    // Wind warning if applicable
                    if weather.windSpeed > 25 {
                        HStack(spacing: 2) {
                            Image(systemName: "wind")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.orange)
                            Text("\(Int(weather.windSpeed))")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.orange)
                        }
                    }
                }
            }
            
            // Warning for unsafe stops
            if stop.safetyStatus.shouldAvoid {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.red)
                    Text(L10n.text("poi_unsafe_stop_warning"))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.red.opacity(0.9))
                }
                .padding(.top, 2)
            }
            
            // Distance from route
            Text(L10n.formatted("poi_distance_from_route", Int(stop.distanceFromRoute)))
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(hex: stop.safetyStatus.color).opacity(0.5), lineWidth: 1)
        )
        .frame(width: 200)
    }
}

// MARK: - Hazard Annotation View
struct HazardAnnotationView: View {
    let hazard: EnvironmentalHazard
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Hazard Marker
            ZStack {
                // Warning glow for critical hazards
                if hazard.severity == .critical || hazard.severity == .high {
                    Circle()
                        .fill(Color(hex: hazard.severity.color).opacity(0.4))
                        .frame(width: isAnimating ? 50 : 35, height: isAnimating ? 50 : 35)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                        .onAppear { isAnimating = true }
                }
                
                // Warning triangle background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 36, height: 36)
                
                // Warning border
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: hazard.severity.color), lineWidth: 2)
                    .frame(width: 36, height: 36)
                
                // Hazard icon
                Image(systemName: hazard.iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: hazard.severity.color))
                    .shadow(color: Color(hex: hazard.severity.color).opacity(0.8), radius: 4)
            }
            .frame(width: 50, height: 50)
            
            // ETA label
            Text(hazard.etaAtLocation.formattedTime())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(hex: hazard.severity.color))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: hazard.severity.color).opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - Date Extension
extension Date {
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            // Safe POI
            SmartPOIAnnotationView(stop: SmartStop(
                id: UUID(),
                mapItem: MKMapItem(),
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                name: "Tesla Supercharger",
                category: .evCharger,
                etaArrival: Date().addingTimeInterval(3600),
                weatherAtArrival: SegmentWeather(
                    condition: .clear,
                    temperature: 22,
                    precipitationChance: 0,
                    windSpeed: 10,
                    visibility: 10,
                    severity: .good
                ),
                safetyStatus: .safe,
                distanceFromRoute: 150,
                estimatedStopDuration: 1800
            ))
            
            // Unsafe POI
            SmartPOIAnnotationView(stop: SmartStop(
                id: UUID(),
                mapItem: MKMapItem(),
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                name: "Shell Gas Station",
                category: .gasStation,
                etaArrival: Date().addingTimeInterval(7200),
                weatherAtArrival: SegmentWeather(
                    condition: .thunderstorm,
                    temperature: 18,
                    precipitationChance: 0.9,
                    windSpeed: 45,
                    visibility: 2,
                    severity: .severe
                ),
                safetyStatus: .dangerous,
                distanceFromRoute: 200,
                estimatedStopDuration: 600
            ))
            
            // Hazard marker
            HazardAnnotationView(hazard: EnvironmentalHazard(
                id: UUID(),
                type: .crosswind,
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                routeSegmentIndex: 5,
                severity: .high,
                details: "Crosswinds up to 45 km/h",
                recommendation: "Reduce speed and hold steering wheel firmly",
                etaAtLocation: Date().addingTimeInterval(5400)
            ))
        }
    }
}
