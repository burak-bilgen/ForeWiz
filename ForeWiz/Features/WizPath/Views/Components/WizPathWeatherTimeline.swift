import SwiftUI

// MARK: - Weather Timeline

struct WizPathWeatherTimeline: View {
    let segments: [WizPathSegment]
    let changePoints: [WizPathSegment]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("wizpath_weather_along_route"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(changePoints) { segment in
                        WizPathWeatherSegmentCard(segment: segment)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - Weather Segment Card

struct WizPathWeatherSegmentCard: View {
    let segment: WizPathSegment

    var body: some View {
        let severityColor = Color(hex: segment.weather?.severity.colorHex ?? "#ffffff")
        return VStack(spacing: 4) {
            if let weather = segment.weather {
                Image(systemName: weather.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(severityColor)
                    .shadow(color: severityColor.opacity(0.3), radius: 3)

                Text("\(Int(weather.temperature))\(L10n.text("unit_degree"))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                Text(segment.etaShortDisplay)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 48, height: 60)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(severityColor.opacity(0.2), lineWidth: 0.5)
        )
    }
}
