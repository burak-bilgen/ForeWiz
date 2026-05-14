import SwiftUI

// MARK: - Journey HUD View
struct JourneyHUDView: View {
    let data: JourneyHUDData
    @State private isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main HUD Bar - Terminal Style
            HStack(spacing: 0) {
                // System indicator
                HStack(spacing: 4) {
                    Text("[ SYSTEM ]")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#00FF41"))
                    
                    // Pulsing status dot
                    Circle()
                        .fill(Color(hex: "#00FF41"))
                        .frame(width: 6, height: 6)
                        .opacity(isExpanded ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isExpanded)
                }
                .padding(.trailing, 8)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 20)
                
                // Route duration
                HUDStatItem(
                    label: "ROUTE",
                    value: data.durationDisplay,
                    color: "#00FF41"
                )
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 20)
                
                // Hazards count
                HUDStatItem(
                    label: "HAZARDS",
                    value: "\(data.hazardCount)",
                    color: data.hazardCount > 0 ? "#FF3B30" : "#00FF41"
                )
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 20)
                
                // Safe stops
                HUDStatItem(
                    label: "SAFE STOPS",
                    value: "\(data.safeStops)",
                    color: data.safeStops > 0 ? "#00FF41" : "#FF9500"
                )
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 20)
                
                // Safety score
                HStack(spacing: 4) {
                    Text("SAFETY:")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.5))
                    
                    Text("\(data.safetyScore)/100")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(safetyScoreColor)
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                // Expand/collapse button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#00FF41").opacity(0.3), lineWidth: 1)
            )
            
            // Expanded details panel
            if isExpanded {
                HUDDetailPanel(
                    hazards: data.activeHazards,
                    nextSafeStop: data.nextSafeStop,
                    safetyScore: data.safetyScore
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var safetyScoreColor: Color {
        switch data.safetyScore {
        case 80...100: return Color(hex: "#00FF41")
        case 60..<80: return Color(hex: "#7FFF00")
        case 40..<60: return Color(hex: "#FFCC00")
        case 20..<40: return Color(hex: "#FF9500")
        default: return Color(hex: "#FF3B30")
        }
    }
}

// MARK: - HUD Stat Item
struct HUDStatItem: View {
    let label: String
    let value: String
    let color: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: color))
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - HUD Detail Panel
struct HUDDetailPanel: View {
    let hazards: [EnvironmentalHazard]
    let nextSafeStop: SmartStop?
    let safetyScore: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Active hazards list
            if !hazards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ ACTIVE HAZARDS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#FF3B30"))
                    
                    ForEach(hazards.prefix(3)) { hazard in
                        HazardRow(hazard: hazard)
                    }
                    
                    if hazards.count > 3 {
                        Text("+\(hazards.count - 3) more hazards...")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
            }
            
            // Next safe stop
            if let stop = nextSafeStop {
                VStack(alignment: .leading, spacing: 6) {
                    Text("✓ NEXT SAFE STOP")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#00FF41"))
                    
                    HStack {
                        Image(systemName: stop.category.iconName)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: stop.category.color))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.displayTitle)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 8) {
                                Text("ETA: \(stop.etaDisplay)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.white.opacity(0.6))
                                
                                if let weather = stop.weatherAtArrival {
                                    HStack(spacing: 2) {
                                        Image(systemName: weather.iconName)
                                            .font(.system(size: 8))
                                        Text("\(Int(weather.temperature))°")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Safety badge
                        Text(stop.safetyStatus.localizedTitle)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color(hex: stop.safetyStatus.color))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: stop.safetyStatus.color).opacity(0.15))
                            )
                    }
                }
            } else {
                Text("⚠️ NO SAFE STOPS ALONG ROUTE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#FF9500"))
            }
            
            // Safety score bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("SAFETY SCORE")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.5))
                    
                    Spacer()
                    
                    Text(safetyRatingText)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(safetyScoreColor)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(safetyScoreColor)
                            .frame(width: geometry.size.width * (Double(safetyScore) / 100.0), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#00FF41").opacity(0.2), lineWidth: 1)
        )
    }
    
    private var safetyRatingText: String {
        switch safetyScore {
        case 80...100: return "EXCELLENT"
        case 60..<80: return "GOOD"
        case 40..<60: return "MODERATE"
        case 20..<40: return "POOR"
        default: return "DANGEROUS"
        }
    }
    
    private var safetyScoreColor: Color {
        switch safetyScore {
        case 80...100: return Color(hex: "#00FF41")
        case 60..<80: return Color(hex: "#7FFF00")
        case 40..<60: return Color(hex: "#FFCC00")
        case 20..<40: return Color(hex: "#FF9500")
        default: return Color(hex: "#FF3B30")
        }
    }
}

// MARK: - Hazard Row
struct HazardRow: View {
    let hazard: EnvironmentalHazard
    
    var body: some View {
        HStack(spacing: 8) {
            // Severity indicator
            Circle()
                .fill(Color(hex: hazard.severity.color))
                .frame(width: 8, height: 8)
            
            // Hazard icon
            Image(systemName: hazard.iconName)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: hazard.severity.color))
                .frame(width: 20)
            
            // Hazard details
            VStack(alignment: .leading, spacing: 1) {
                Text(hazard.localizedTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text("at \(hazard.etaAtLocation.formattedTime())")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            // Severity badge
            Text(hazard.severity.localizedTitle)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color(hex: hazard.severity.color))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: hazard.severity.color).opacity(0.15))
                )
        }
    }
}

// MARK: - Route Alternative Banner
struct RouteAlternativeBanner: View {
    let comparison: RouteComparisonResult
    let onSelectAlternative: () -> Void
    
    var body: some View {
        if comparison.shouldShowAlternative,
           let message = comparison.alternativeMessage {
            HStack(spacing: 12) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#FF9500"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("SAFER ALTERNATIVE AVAILABLE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#FF9500"))
                    
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Switch button
                Button(action: onSelectAlternative) {
                    Text("SWITCH")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "#00FF41"))
                        )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#FF9500").opacity(0.5), lineWidth: 2)
            )
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 20) {
            JourneyHUDView(data: JourneyHUDData(
                totalDuration: 8100, // 2h 15m
                totalDistance: 145000,
                hazardCount: 1,
                safeStops: 3,
                safetyScore: 72,
                activeHazards: [
                    EnvironmentalHazard(
                        id: UUID(),
                        type: .crosswind,
                        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                        routeSegmentIndex: 5,
                        severity: .high,
                        details: "Crosswinds up to 45 km/h",
                        recommendation: "Reduce speed",
                        etaAtLocation: Date().addingTimeInterval(5400)
                    )
                ],
                nextSafeStop: SmartStop(
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
                )
            ))
            
            RouteAlternativeBanner(
                comparison: RouteComparisonResult(
                    fastestRoute: nil,
                    fastestScore: RouteSafetyScore(
                        overallScore: 45,
                        weatherScore: 20,
                        hazardScore: 15,
                        poiScore: 10,
                        hazardCount: 2,
                        safeStopCount: 0,
                        unsafeStopCount: 2,
                        recommendedAlternatives: []
                    ),
                    recommendedAlternative: nil,
                    timeDifference: 15 * 60, // 15 minutes
                    allRoutes: []
                ),
                onSelectAlternative: {}
            )
        }
    }
}
