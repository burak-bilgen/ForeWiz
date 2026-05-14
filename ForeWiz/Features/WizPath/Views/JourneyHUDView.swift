import SwiftUI
@preconcurrency import MapKit
import CoreLocation

// MARK: - Journey HUD View (Native iOS Design)
struct JourneyHUDView: View {
    let data: JourneyHUDData
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main HUD Bar - Native iOS Style
            HStack(spacing: 0) {
                // Icon
                Circle()
                    .fill(safetyTint.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: safetyIcon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(safetyTint)
                    )

                // Stats
                HStack(spacing: 0) {
                    StatItem(
                        value: data.durationDisplay,
                        label: "ETA",
                        color: .primary
                    )

                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 8)

                    StatItem(
                        value: "\(data.hazardCount)",
                        label: "Hazards",
                        color: data.hazardCount > 0 ? .orange : .secondary
                    )

                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 8)

                    StatItem(
                        value: "\(data.safetyScore)",
                        label: "Safety",
                        color: safetyTint
                    )
                }

                Spacer()

                // Expand
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                        HapticEngine.shared.light()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 28, height: 28)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(safetyTint.opacity(0.15), lineWidth: 1)
            )

            // Expanded Details
            if isExpanded {
                HUDDetailPanel(
                    safetyScore: data.safetyScore,
                    hazards: data.activeHazards,
                    nextSafeStop: data.nextSafeStop
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 6)
            }
        }
    }

    private var safetyTint: Color {
        switch data.safetyScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var safetyIcon: String {
        switch data.safetyScore {
        case 80...100: return "checkmark.shield.fill"
        case 60..<80: return "shield.fill"
        case 40..<60: return "exclamationmark.shield.fill"
        default: return "xmark.shield.fill"
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - HUD Detail Panel
struct HUDDetailPanel: View {
    let safetyScore: Int
    let hazards: [EnvironmentalHazard]
    let nextSafeStop: SmartStop?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Safety Score Bar
            safetyScoreBar

            // Active Hazards
            if !hazards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(hazards.count) Active Hazard\(hazards.count > 1 ? "s" : "")", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.orange)

                    ForEach(hazards.prefix(3)) { hazard in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: hazard.severity.color))
                                .frame(width: 6, height: 6)

                            Image(systemName: hazard.iconName)
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: hazard.severity.color))
                                .frame(width: 16)

                            Text(hazard.localizedTitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(hazard.severity.localizedTitle)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color(hex: hazard.severity.color))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: hazard.severity.color).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    if hazards.count > 3 {
                        Text("+\(hazards.count - 3) more")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Next Safe Stop
            if let stop = nextSafeStop {
                HStack(spacing: 10) {
                    Circle()
                        .fill(.green.opacity(0.12))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: stop.category.iconName)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: stop.category.color))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.displayTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Label(stop.etaDisplay, systemImage: "clock")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)

                            if let weather = stop.weatherAtArrival {
                                Label("\(Int(weather.temperature))°", systemImage: weather.iconName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    Spacer()

                    Text(stop.safetyStatus.localizedTitle)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(hex: stop.safetyStatus.color))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: stop.safetyStatus.color).opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var safetyScoreBar: some View {
        VStack(spacing: 6) {
            HStack {
                Label("Journey Safety", systemImage: "shield.checkered")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(safetyRatingText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(safetyScoreColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(safetyScoreColor)
                        .frame(width: geometry.size.width * (Double(safetyScore) / 100.0), height: 6)
                        .animation(.spring(response: 0.6), value: safetyScore)
                }
            }
            .frame(height: 6)
        }
    }

    private var safetyRatingText: String {
        switch safetyScore {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Moderate"
        case 20..<40: return "Poor"
        default: return "Dangerous"
        }
    }

    private var safetyScoreColor: Color {
        switch safetyScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        case 20..<40: return .orange
        default: return .red
        }
    }
}

// MARK: - Hazard Row (Reusable)
struct HazardRow: View {
    let hazard: EnvironmentalHazard

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: hazard.severity.color))
                .frame(width: 6, height: 6)

            Image(systemName: hazard.iconName)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: hazard.severity.color))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(hazard.localizedTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("at \(hazard.etaAtLocation.formattedTime())")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(hazard.severity.localizedTitle)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color(hex: hazard.severity.color))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(hex: hazard.severity.color).opacity(0.12))
                .clipShape(Capsule())
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
        Color(.systemGroupedBackground).ignoresSafeArea()

        VStack(spacing: 20) {
            JourneyHUDView(data: JourneyHUDData(
                totalDuration: 8100,
                totalDistance: 145000,
                hazardCount: 2,
                safeStops: 3,
                safetyScore: 72,
                activeHazards: [
                    EnvironmentalHazard(
                        id: UUID(),
                        type: .crosswind,
                        coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
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
                    coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                    name: "Shell Station",
                    category: .gasStation,
                    etaArrival: Date().addingTimeInterval(3600),
                    weatherAtArrival: nil,
                    safetyStatus: .safe,
                    distanceFromRoute: 150,
                    estimatedStopDuration: 600
                )
            ))
            .padding(.horizontal, 16)
        }
    }
}
