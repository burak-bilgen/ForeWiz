import SwiftUI

// MARK: - Weather Timeline

public struct WizPathWeatherTimeline: View {
    let segments: [WizPathSegment]
    let changePoints: [WizPathSegment]
    @State private var selectedSegment: WizPathSegment?

    public init(segments: [WizPathSegment], changePoints: [WizPathSegment]) { self.segments = segments; self.changePoints = changePoints }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(WizPathKitL10n.text("wizpath_weather_along_route"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("\(changePoints.count) \(WizPathKitL10n.text("wizpath_weather_changes"))")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(changePoints) { segment in
                        WizPathWeatherSegmentCard(segment: segment, isSelected: selectedSegment?.id == segment.id)
                            .onTapGesture {
                                withAnimation(AppTheme.pressSpring) {
                                    selectedSegment = selectedSegment?.id == segment.id ? nil : segment
                                    HapticEngine.shared.light()
                                }
                            }
                    }
                }.padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - Weather Segment Card

public struct WizPathWeatherSegmentCard: View {
    let segment: WizPathSegment
    let isSelected: Bool
    public init(segment: WizPathSegment, isSelected: Bool = false) { self.segment = segment; self.isSelected = isSelected }
    public var body: some View {
        let severityColor = Color(hex: segment.weather?.severity.colorHex ?? "#ffffff")
        let expandedWidth: CGFloat = isSelected ? 72 : 48
        return VStack(spacing: 4) {
            if let weather = segment.weather {
                Image(systemName: weather.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(severityColor)
                    .shadow(color: severityColor.opacity(0.3), radius: 3)
                Text(WizPathKitL10n.formatted("wizpath_temperature_format", Int(weather.temperature)))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Text(segment.etaDisplay)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.tertiary)
                if isSelected {
                    Group {
                        HStack(spacing: 3) {
                            Image(systemName: "wind")
                                .font(.system(size: 7))
                            Text(verbatim: "\(Int(weather.windSpeed))")
                                .font(.system(size: 8, weight: .semibold))
                        }
                        HStack(spacing: 3) {
                            Image(systemName: "drop")
                                .font(.system(size: 7))
                            Text(verbatim: "\(Int(weather.precipitationChance * 100))%")
                                .font(.system(size: 8, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(width: expandedWidth)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? severityColor.opacity(0.1) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? severityColor.opacity(0.4) : severityColor.opacity(0.2), lineWidth: isSelected ? 1 : 0.5)
        )
        .animation(AppTheme.pressSpring, value: isSelected)
    }
}
