import SwiftUI
@preconcurrency import MapKit
import CoreLocation

// MARK: - WizPath Dashboard View
struct WizPathDashboardView: View {
    @StateObject private var viewModel = WizPathViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Trip Planner (Collapsible)
                TripPlannerView(viewModel: viewModel)
                
                // Map with Route Overlay
                WizPathMapView(viewModel: viewModel)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                // Route Detail Cards
                if let route = viewModel.currentRoute {
                    RouteDetailPanel(route: route)
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task { await HapticEngine.shared.light() }
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text(L10n.text("wizpath_title"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .alert("Route Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Trip Planner View
struct TripPlannerView: View {
    @ObservedObject var viewModel: WizPathViewModel
    @State private var showDestinationPicker = false
    @State private var showTimePicker = false
    
    var body: some View {
        GlassCard(accentColor: Color(red: 0.0, green: 1.0, blue: 0.25)) {
            VStack(spacing: 16) {
                // Destination Input
                DestinationInputField(
                    destination: $viewModel.destinationName,
                    onTap: { showDestinationPicker = true }
                )
                
                // Mode Toggle + Time Picker
                HStack(spacing: 12) {
                    // Travel Mode Toggle
                    TravelModeToggle(mode: $viewModel.travelMode)
                    
                    // Departure Time
                    DepartureTimePicker(
                        departureTime: $viewModel.departureTime,
                        showPicker: $showTimePicker
                    )
                }
                
                // Calculate Button
                CalculateButton(
                    isLoading: viewModel.isCalculating,
                    isEnabled: viewModel.canCalculate,
                    action: {
                        Task {
                            await viewModel.calculateRoute()
                        }
                    }
                )
            }
            .padding(16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .sheet(isPresented: $showDestinationPicker) {
            DestinationPickerView(
                onSelect: { location in
                    viewModel.setDestination(location)
                    showDestinationPicker = false
                }
            )
        }
    }
}

// MARK: - Destination Input Field
struct DestinationInputField: View {
    @Binding var destination: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(red: 0.0, green: 1.0, blue: 0.25))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("wizpath_destination"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                    
                    Text(destination.isEmpty ? L10n.text("wizpath_tap_to_select") : destination)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(destination.isEmpty ? Color.white.opacity(0.3) : .white)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(red: 0.0, green: 1.0, blue: 0.25).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Travel Mode Toggle
struct TravelModeToggle: View {
    @Binding var mode: TravelMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TravelMode.allCases) { travelMode in
                Button {
                    Task { await HapticEngine.shared.selectionChanged() }
                    mode = travelMode
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: travelMode.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(travelMode.localizedTitle)
                            .font(.system(size: 13, weight: mode == travelMode ? .semibold : .regular))
                    }
                    .foregroundStyle(mode == travelMode ? .black : Color.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        mode == travelMode ?
                            Color(red: 0.0, green: 1.0, blue: 0.25) :
                            Color.white.opacity(0.05)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Departure Time Picker
struct DepartureTimePicker: View {
    @Binding var departureTime: Date
    @Binding var showPicker: Bool
    
    var body: some View {
        Button {
            Task { await HapticEngine.shared.selectionChanged() }
            showPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                Text(formattedTime(departureTime))
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Color.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPicker) {
            DatePicker(
                L10n.text("wizpath_departure_time"),
                selection: $departureTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .frame(width: 300, height: 250)
            .padding()
            .presentationCompactAdaptation(.none)
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Calculate Button
struct CalculateButton: View {
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(isLoading ? L10n.text("wizpath_calculating") : L10n.text("wizpath_calculate"))
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isEnabled ?
                    Color(red: 0.0, green: 1.0, blue: 0.25) :
                    Color.white.opacity(0.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(.plain)
    }
}

// MARK: - Route Detail Panel
struct RouteDetailPanel: View {
    let route: WizPathRoute
    @State private var selectedSegment: WizPathSegment?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Risk Summary Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("wizpath_route_weather"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: route.overallRisk.color))
                            .frame(width: 8, height: 8)
                        Text(route.overallRisk.localizedTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: route.overallRisk.color))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(L10n.text("wizpath_total_time"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text(formattedDuration(route.totalDuration))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Weather Change Points
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(route.weatherChangePoints) { segment in
                        WeatherChangeCard(segment: segment)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

// MARK: - Weather Change Card
struct WeatherChangeCard: View {
    let segment: WizPathSegment
    
    var body: some View {
        VStack(spacing: 8) {
            if let weather = segment.weather {
                Image(systemName: weather.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(weather.severity.color)
                    .shadow(color: weather.severity.color.opacity(0.5), radius: 8)
                
                Text(segment.etaDisplay)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text("\(Int(weather.temperature))°")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.7)
            }
        }
        .frame(width: 70, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(segment.weather?.severity.color.opacity(0.3) ?? Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Weather Severity Color Extension
extension SegmentWeatherSeverity {
    var color: Color {
        switch self {
        case .good: return Color(red: 0.0, green: 1.0, blue: 0.25) // Neon Green
        case .fair: return Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow
        case .caution: return Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
        case .severe: return Color(red: 1.0, green: 0.23, blue: 0.19) // Red
        }
    }
}
