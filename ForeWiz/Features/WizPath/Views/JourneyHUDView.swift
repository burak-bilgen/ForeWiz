import SwiftUI
@preconcurrency import MapKit
import CoreLocation

// MARK: - Journey HUD View
struct JourneyHUDView: View {
    let data: JourneyHUDData
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main HUD Bar
            LiquidGlassCard(accentColor: safetyTint, innerPadding: 0, cornerRadius: 16) {
                HStack(spacing: 0) {
                    // Safety Icon
                    ZStack {
                        Circle()
                            .fill(safetyTint.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: safetyIcon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(safetyTint)
                    }
                    .padding(.leading, 12)

                    // Stats
                    HStack(spacing: 0) {
                        StatItem(value: data.durationDisplay, label: L10n.text("hud_eta"), color: .white)
                        Divider().frame(height: 20).padding(.horizontal, 8).overlay(Color.white.opacity(0.1))
                        StatItem(value: "\(data.hazardCount)", label: L10n.text("hud_hazards"), color: data.hazardCount > 0 ? Color.warning : .secondary)
                        Divider().frame(height: 20).padding(.horizontal, 8).overlay(Color.white.opacity(0.1))
                        StatItem(value: "\(data.safetyScore)", label: L10n.text("hud_safety"), color: safetyTint)
                    }
                    .padding(.horizontal, 8)

                    Spacer(minLength: 0)

                    // Expand Button
                    Button {
                        withAnimation(AppTheme.cardSpring) {
                            isExpanded.toggle()
                            HapticEngine.shared.light()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .contentShape(Rectangle())

                    .buttonStyle(.plain)
                    .padding(.trailing, 10)
                }
                .padding(.vertical, 10)
            }

            // Expanded Panel
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
        case 80...100: return .success
        case 60..<80: return .liquidAccent
        case 40..<60: return .warning
        default: return .danger
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
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 14, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                // Safety Score
                safetyScoreBar

                // Active Hazards
                if !hazards.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.warning)
                            Text(hazards.count == 1 ? L10n.text("hud_active_hazard_singular") : L10n.formatted("hud_active_hazard_plural", hazards.count))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.warning)
                        }

                        ForEach(hazards.prefix(3)) { hazard in
                            HazardRow(hazard: hazard)
                        }

                        if hazards.count > 3 {
                            Text(L10n.formatted("hud_more", hazards.count - 3))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(10)
                    .background(Color.warning.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Next Safe Stop
                if let stop = nextSafeStop {
                    nextStopCard(stop)
                }
            }
        }
    }

    private func nextStopCard(_ stop: SmartStop) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.success.opacity(0.12))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: stop.category.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: stop.category.color))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(stop.displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(stop.etaDisplay, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    if let weather = stop.weatherAtArrival {
                        Label("\(Int(weather.temperature))\(L10n.text("unit_degree"))", systemImage: weather.iconName)
                            .font(.caption)
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
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var safetyScoreBar: some View {
        VStack(spacing: 6) {
            HStack {
                Label(L10n.text("hud_journey_safety"), systemImage: "shield.checkered")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(safetyRatingText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(safetyScoreColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(safetyScoreColor)
                        .frame(width: geometry.size.width * (Double(safetyScore) / 100.0), height: 6)
                        .animation(AppTheme.sheetSpring, value: safetyScore)
                }
            }
            .frame(height: 6)
        }
    }

    private var safetyRatingText: String {
        switch safetyScore {
        case 80...100: return L10n.text("hud_rating_excellent")
        case 60..<80: return L10n.text("hud_rating_good")
        case 40..<60: return L10n.text("hud_rating_moderate")
        case 20..<40: return L10n.text("hud_rating_poor")
        default: return L10n.text("hud_rating_dangerous")
        }
    }

    private var safetyScoreColor: Color {
        switch safetyScore {
        case 80...100: return .success
        case 60..<80: return .liquidAccent
        case 40..<60: return .warning
        default: return .danger
        }
    }
}

// MARK: - Hazard Row
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
                    .foregroundStyle(.white)
                Text(L10n.formatted("hud_at_time", hazard.etaAtLocation.formattedTime()))
                    .font(.caption)
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
        SharedFormatters.shortTime.string(from: self)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: 20) {
            JourneyHUDView(data: JourneyHUDData(
                totalDuration: 8100,
                totalDistance: 145000,
                hazardCount: 2,
                safeStops: 3,
                safetyScore: 72,
                activeHazards: [
                    EnvironmentalHazard(
                        id: UUID(), type: .crosswind,
                        coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                        routeSegmentIndex: 5, severity: .high,
                        details: "Crosswinds up to 45 km/h",
                        recommendation: "Reduce speed",
                        etaAtLocation: Date().addingTimeInterval(5400)
                    )
                ],
                nextSafeStop: SmartStop(
                    id: UUID(), mapItem: MKMapItem(),
                    coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                    name: "Shell Station",
                    category: .gasStation, etaArrival: Date().addingTimeInterval(3600),
                    weatherAtArrival: nil, safetyStatus: .safe,
                    distanceFromRoute: 150, estimatedStopDuration: 600
                )
            ))
            .padding(.horizontal, 16)
        }
    }
}
