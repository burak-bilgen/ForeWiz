import SwiftUI

// MARK: - Weather Timeline

public struct WizPathWeatherTimeline: View {
    let segments: [WizPathSegment]
    let changePoints: [WizPathSegment]

    public init(segments: [WizPathSegment], changePoints: [WizPathSegment]) { self.segments = segments; self.changePoints = changePoints }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(WizPathKitL10n.text("wizpath_weather_along_route")).font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(changePoints) { segment in WizPathWeatherSegmentCard(segment: segment) }
                }.padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - Weather Segment Card

public struct WizPathWeatherSegmentCard: View {
    let segment: WizPathSegment
    public init(segment: WizPathSegment) { self.segment = segment }
    public var body: some View {
        let severityColor = Color(hex: segment.weather?.severity.colorHex ?? "#ffffff")
        return VStack(spacing: 4) {
            if let weather = segment.weather {
                Image(systemName: weather.iconName).font(.system(size: 16)).foregroundStyle(severityColor).shadow(color: severityColor.opacity(0.3), radius: 3)
                Text(WizPathKitL10n.formatted("wizpath_temperature_format", Int(weather.temperature))).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                Text(segment.etaDisplay).font(.system(size: 8, weight: .medium)).foregroundStyle(.tertiary)
            }
        }
        .frame(width: 48, height: 60).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(severityColor.opacity(0.2), lineWidth: 0.5))
    }
}
