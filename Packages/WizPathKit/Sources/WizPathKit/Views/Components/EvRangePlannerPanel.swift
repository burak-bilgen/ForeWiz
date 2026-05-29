import SwiftUI

// MARK: - EV Charging Stops Panel
/// Shows charging stations along the route with estimated arrival times.
/// Range estimates, consumption, and battery-level calculations were removed
/// because they relied on hardcoded assumptions (400 km base range, 75 kWh battery,
/// 80 % starting charge) rather than real vehicle data.
public struct EvRangePlannerPanel: View {
    let chargingStations: [SmartStop]

    public init(
        chargingStations: [SmartStop]
    ) {
        self.chargingStations = chargingStations
    }

    public var body: some View {
        LiquidGlassCard(accentColor: Color(hex: "#00D9FF"), innerPadding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "bolt.car.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#00D9FF"))
                    Text(WizPathKitL10n.text("wizpath_ev_mode_title"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "battery.100.bolt")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#00D9FF"))
                }

                // Charging Stations Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(WizPathKitL10n.text("ev_charging_stops_title"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 4)

                    if !chargingStations.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(chargingStations.enumerated()), id: \.element.id) { index, station in
                                HStack(alignment: .center, spacing: 10) {
                                    // Dot node
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: "#00D9FF"))
                                            .frame(width: 8, height: 8)
                                            .shadow(color: Color(hex: "#00D9FF").opacity(0.5), radius: 4)
                                    }

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(station.displayTitle)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.white)
                                        
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 9))
                                            Text(station.etaDisplay)
                                                .font(.system(size: 11))
                                        }
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer()

                                    // Safety / category badge
                                    if station.safetyStatus != .safe {
                                        Text(station.safetyStatus.localizedTitle)
                                            .font(.system(size: 8, weight: .semibold))
                                            .foregroundStyle(Color(hex: station.safetyStatus.color))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(hex: station.safetyStatus.color).opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#30D158"))

                            Text(WizPathKitL10n.text("ev_no_stops_needed"))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}
