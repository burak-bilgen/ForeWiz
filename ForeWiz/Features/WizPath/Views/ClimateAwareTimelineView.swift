import SwiftUI

// MARK: - Climate-Aware Departure Timeline View
struct ClimateAwareTimelineView: View {
    let slots: [DepartureSlot]
    let selectedSlot: DepartureSlot?
    let onSelect: (DepartureSlot) -> Void
    let weatherUnavailableMessage: String?

    var body: some View {
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                headerView

                if let message = weatherUnavailableMessage {
                    WeatherUnavailableBanner(message: message)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(slots) { slot in
                            TimelineBar(
                                slot: slot,
                                isSelected: selectedSlot?.id == slot.id,
                                onTap: { onSelect(slot) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }

                if let selected = selectedSlot {
                    SelectedSlotDetail(slot: selected)
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("wizpath_departure_times"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Text(L10n.text("wizpath_optimal_windows"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                LegendItem(color: .success, label: L10n.text("wizpath_optimal"))
                LegendItem(color: .warning, label: L10n.text("wizpath_caution_short"))
                LegendItem(color: .danger, label: L10n.text("wizpath_avoid"))
            }
        }
    }
}

// MARK: - Timeline Bar
struct TimelineBar: View {
    let slot: DepartureSlot
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(slot.timeLabel)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .secondary)

                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(barColor.opacity(0.15))
                        .frame(width: 48, height: 72)

                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 8)
                            .fill(barGradient)
                            .frame(width: 48, height: 72 * fillPercentage)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white, lineWidth: 2)
                            .frame(width: 48, height: 72)
                            .shadow(color: .white.opacity(0.2), radius: 4)
                    }

                    if slot.hasWeatherDataError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.warning)
                            .offset(y: -20)
                    }
                }
                .frame(width: 48, height: 72)

                Text("\\(Int(slot.temperature))°")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(temperatureColor)

                Text(slot.durationLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 60)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var barColor: Color {
        if slot.hasWeatherDataError { return .gray }
        else if slot.temperature >= 40 || slot.score < 40 { return .danger }
        else if slot.temperature >= 36 || slot.score < 60 { return .warning }
        else { return .success }
    }

    private var barGradient: LinearGradient {
        if slot.hasWeatherDataError {
            return LinearGradient(
                colors: [.gray.opacity(0.6), .gray.opacity(0.3)],
                startPoint: .bottom, endPoint: .top
            )
        } else if slot.temperature >= 40 || slot.score < 40 {
            return LinearGradient(
                colors: [.danger.opacity(0.7), .danger.opacity(0.3)],
                startPoint: .bottom, endPoint: .top
            )
        } else if slot.temperature >= 36 || slot.score < 60 {
            return LinearGradient(
                colors: [.warning.opacity(0.7), .warning.opacity(0.3)],
                startPoint: .bottom, endPoint: .top
            )
        } else {
            return LinearGradient(
                colors: [.success.opacity(0.7), .success.opacity(0.3)],
                startPoint: .bottom, endPoint: .top
            )
        }
    }

    private var fillPercentage: CGFloat {
        let baseScore = CGFloat(slot.score) / 100.0
        if slot.temperature >= 40 { return baseScore * 0.5 }
        else if slot.temperature >= 36 { return baseScore * 0.7 }
        else if slot.hasWeatherDataError { return baseScore * 0.6 }
        return baseScore
    }

    private var temperatureColor: Color {
        if slot.hasWeatherDataError { return .secondary }
        else if slot.temperature >= 40 { return .danger }
        else if slot.temperature >= 36 { return .warning }
        else { return .secondary }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.4), radius: 2)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Weather Unavailable Banner
struct WeatherUnavailableBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.warning)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Selected Slot Detail
struct SelectedSlotDetail: View {
    let slot: DepartureSlot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(slot.timeLabel)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text(slot.displayStatus)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(statusColor)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.3), lineWidth: 3)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: CGFloat(slot.score) / 100.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("\\(slot.score)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.06))

            HStack(spacing: 20) {
                DetailItem(icon: "clock.fill", label: L10n.text("wizpath_duration"), value: slot.durationLabel)
                DetailItem(icon: "thermometer", label: L10n.text("wizpath_temperature"), value: "\\(Int(slot.temperature))°C")
                if slot.hasWeatherDataError {
                    DetailItem(icon: "exclamationmark.triangle.fill", label: L10n.text("wizpath_status"), value: L10n.text("wizpath_estimates_only"))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusColor: Color {
        if slot.hasWeatherDataError { return .warning }
        else if slot.score >= 80 { return .success }
        else if slot.score >= 60 { return .warning }
        else { return .danger }
    }

    private var scoreColor: Color {
        if slot.hasWeatherDataError { return .gray }
        else if slot.score >= 80 { return .success }
        else if slot.score >= 60 { return .warning }
        else { return .danger }
    }
}

// MARK: - Detail Item
struct DetailItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 70)
    }
}
