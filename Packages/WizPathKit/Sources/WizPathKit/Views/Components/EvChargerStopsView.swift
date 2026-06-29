import SwiftUI

public struct EvChargerStopsView: View {
    let chargingStations: [SmartStop]
    let isLoading: Bool
    let errorMessage: String?
    let onRefresh: () -> Void

    public init(
        chargingStations: [SmartStop],
        isLoading: Bool,
        errorMessage: String?,
        onRefresh: @escaping () -> Void
    ) {
        self.chargingStations = chargingStations
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.onRefresh = onRefresh
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.car.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.green)
                Text(WizPathKitL10n.text("wizpath_ev_chargers"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white.opacity(0.6))
                } else {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange)
            }

            if !chargingStations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(chargingStations) { station in
                            EvChargerStationCard(station: station)
                        }
                    }
                }
            } else if !isLoading && errorMessage == nil {
                Text(WizPathKitL10n.text("wizpath_no_chargers_found"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 0.5)
                )
        )
        .environment(\.colorScheme, .dark)
    }
}

struct EvChargerStationCard: View {
    let station: SmartStop

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.green)
                Text(station.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            if station.distanceFromRoute > 0 {
                Text(formatDistance(station.distanceFromRoute))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
}
