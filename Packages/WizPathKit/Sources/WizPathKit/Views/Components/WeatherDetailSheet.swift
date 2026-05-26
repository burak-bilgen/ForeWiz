import SwiftUI

// MARK: - Weather Detail Sheet

public struct WeatherDetailSheet: View {
    let segment: WizPathSegment
    let weather: SegmentWeather
    @Environment(\.dismiss) private var dismiss

    public init(segment: WizPathSegment, weather: SegmentWeather) {
        self.segment = segment
        self.weather = weather
    }

    public var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 20) {
                    // Hero header
                    LiquidGlassCard(accentColor: severityColor, innerPadding: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: weather.iconName)
                                .font(.system(size: 48))
                                .foregroundStyle(severityColor)
                                .shadow(color: severityColor.opacity(0.3), radius: 8)
                                .symbolRenderingMode(.multicolor)

                            Text(weather.condition.localizedTitle)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)

                            HStack(spacing: 16) {
                                Label(WizPathKitL10n.formatted("wizpath_temperature_format", Int(weather.temperature)), systemImage: "thermometer.medium")
                                Label(WizPathKitL10n.formatted("wizpath_wind_speed_format", Int(weather.windSpeed)), systemImage: "wind")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        }
                    }

                    // Details grid
                    LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 16) {
                        VStack(spacing: 12) {
                            detailRow(icon: "clock.fill", label: WizPathKitL10n.text("wizpath_weather_eta"), value: segment.etaDisplay)
                            detailRow(icon: "drop.fill", label: WizPathKitL10n.text("wizpath_weather_precipitation"), value: "\(Int(weather.precipitationChance * 100))%")
                            detailRow(icon: "eye.fill", label: WizPathKitL10n.text("wizpath_weather_visibility"), value: visibilityDisplay)
                            detailRow(icon: "exclamationmark.triangle.fill", label: WizPathKitL10n.text("wizpath_weather_severity"), value: severityDisplay)
                        }
                    }

                    // Safety recommendation
                    LiquidGlassCard(accentColor: severityColor, innerPadding: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(severityColor)
                                Text(WizPathKitL10n.text("wizpath_weather_recommendation"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            Text(recommendationText)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(WizPathKitL10n.text("wizpath_weather_detail_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.liquidAccent)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var severityColor: Color {
        Color(hex: weather.severity.colorHex)
    }

    private var visibilityDisplay: String {
        guard let vis = weather.visibility else { return WizPathKitL10n.text("weather_visibility_na") }
        if vis >= 10 { return WizPathKitL10n.text("weather_visibility_high") }
        return String(format: WizPathKitL10n.text("weather_visibility_value"), vis)
    }

    private var severityDisplay: String {
        switch weather.severity {
        case .good: return WizPathKitL10n.text("wizpath_severity_good")
        case .fair: return WizPathKitL10n.text("wizpath_severity_fair")
        case .caution: return WizPathKitL10n.text("wizpath_severity_caution")
        case .severe: return WizPathKitL10n.text("wizpath_severity_severe")
        }
    }

    private var recommendationText: String {
        switch weather.condition {
        case .thunderstorm:
            return WizPathKitL10n.text("wizpath_rec_thunderstorm")
        case .heavyRain:
            return WizPathKitL10n.text("wizpath_rec_heavy_rain")
        case .snow, .sleet:
            return WizPathKitL10n.text("wizpath_rec_snow")
        case .fog:
            return WizPathKitL10n.text("wizpath_rec_fog")
        case .windy where weather.windSpeed > 50:
            return WizPathKitL10n.text("wizpath_rec_high_wind")
        case .rain:
            return WizPathKitL10n.text("wizpath_rec_rain")
        default:
            if weather.temperature > 35 {
                return WizPathKitL10n.text("wizpath_rec_extreme_heat")
            } else if weather.temperature < 0 {
                return WizPathKitL10n.text("wizpath_rec_freezing")
            }
            return WizPathKitL10n.text("wizpath_rec_normal")
        }
    }
}
