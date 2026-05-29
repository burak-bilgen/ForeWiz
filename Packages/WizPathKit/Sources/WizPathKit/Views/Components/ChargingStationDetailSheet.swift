import SwiftUI
import CoreLocation

// MARK: - Charging Station Detail Sheet

public struct ChargingStationDetailSheet: View {
    let station: SmartStop
    @Environment(\.dismiss) private var dismiss

    public init(station: SmartStop) {
        self.station = station
    }

    public var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card (Full Width)
                    LiquidGlassCard(accentColor: Color(hex: station.category.color), innerPadding: 24) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: station.category.color).opacity(0.18))
                                    .frame(width: 76, height: 76)
                                Image(systemName: station.category.iconName)
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(Color(hex: station.category.color))
                                    .shadow(color: Color(hex: station.category.color).opacity(0.4), radius: 8)
                            }

                            Text(station.displayTitle)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: station.safetyStatus.color))
                                    .frame(width: 8, height: 8)
                                Text(station.safetyStatus.localizedTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: station.safetyStatus.color))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: station.safetyStatus.color).opacity(0.12), in: Capsule())
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)

                    // Weather at Arrival Card (if available)
                    if let weather = station.weatherAtArrival {
                        LiquidGlassCard(accentColor: Color(hex: weather.severity.colorHex), innerPadding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "cloud.sun.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: weather.severity.colorHex))
                                    Text(WizPathKitL10n.text("wizpath_weather_at_arrival"))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }

                                Divider().overlay(Color.white.opacity(0.08))

                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: weather.severity.colorHex).opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: weather.iconName)
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color(hex: weather.severity.colorHex))
                                            .symbolRenderingMode(.multicolor)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(WizPathKitL10n.formatted("wizpath_temperature_format", Int(weather.temperature)))
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "wind")
                                                .font(.system(size: 10))
                                            Text(WizPathKitL10n.formatted("wizpath_wind_speed_format", Int(weather.windSpeed)))
                                        }
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text(weather.condition.localizedTitle)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Weather Advisor Recommendation Card
                    if let recommendation = station.weatherRecommendation {
                        LiquidGlassCard(accentColor: Color(hex: station.safetyStatus.color), innerPadding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: station.safetyStatus.color))
                                    Text(WizPathKitL10n.text("wizpath_smart_route_advisor"))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    if station.safetyStatus.shouldAvoid {
                                        Text(WizPathKitL10n.text("wizpath_avoid"))
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.danger, in: RoundedRectangle(cornerRadius: 4))
                                    }
                                }

                                Divider().overlay(Color.white.opacity(0.08))

                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: station.safetyStatus.color).opacity(0.15))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: station.safetyStatus.shouldAvoid ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(Color(hex: station.safetyStatus.color))
                                    }

                                    Text(recommendation)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Stop Stats Card
                    let stopMins = Int(station.estimatedStopDuration / 60)
                    let stopDurationDisplay = WizPathKitL10n.formatted("wizpath_duration_minutes_short", stopMins)
                    LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 16) {
                        VStack(spacing: 12) {
                            detailRow(icon: "arrow.triangle.swap", label: WizPathKitL10n.text("wizpath_distance_from_route"), value: WizPathKitFormatters.formattedDistance(station.distanceFromRoute))
                            detailRow(icon: "clock.fill", label: WizPathKitL10n.text("wizpath_estimated_arrival_eta"), value: station.etaDisplay)
                            detailRow(icon: "hourglass", label: WizPathKitL10n.text("wizpath_estimated_stop_duration"), value: stopDurationDisplay)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)

                    // Legal Disclaimer Card
                    LiquidGlassCard(accentColor: .warning, innerPadding: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.warning.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.warning)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(WizPathKitL10n.text("wizpath_disclaimer_title"))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text(WizPathKitL10n.text("wizpath_disclaimer_desc"))
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)

                    // Navigation Action Card
                    LiquidGlassCard(accentColor: Color(hex: station.category.color), innerPadding: 16) {
                        VStack(spacing: 12) {
                            Text(WizPathKitL10n.text("wizpath_navigation_action_desc"))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 12) {
                                PremiumGlassMapButton(
                                    title: WizPathKitL10n.text("wizpath_apple_maps"),
                                    icon: "map.fill",
                                    gradientColors: [.blue, Color(red: 0.1, green: 0.6, blue: 0.95)]
                                ) {
                                    openInAppleMaps()
                                }

                                PremiumGlassMapButton(
                                    title: WizPathKitL10n.text("wizpath_google_maps"),
                                    icon: "arrow.triangle.turn.up.right.diamond.fill",
                                    gradientColors: [Color(red: 0.15, green: 0.65, blue: 0.35), Color(red: 0.25, green: 0.75, blue: 0.55)]
                                ) {
                                    openInGoogleMaps()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .navigationTitle(station.category.defaultName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
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

    private func openInAppleMaps() {
        let lat = station.coordinate.latitude
        let lon = station.coordinate.longitude
        let defaultName = station.category.defaultName
        let name = station.displayTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? defaultName
        guard
            let url = URL(string: "maps://?q=\(name)&ll=\(lat),\(lon)&z=14"),
            let webURL = URL(string: "https://maps.apple.com/?q=\(name)&ll=\(lat),\(lon)&z=14")
        else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }

    private func openInGoogleMaps() {
        let lat = station.coordinate.latitude
        let lon = station.coordinate.longitude
        guard
            let appURL = URL(string: "comgooglemaps://?q=\(lat),\(lon)&zoom=14"),
            let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(lat),\(lon)")
        else { return }
        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - Premium Glass Map Button

struct PremiumGlassMapButton: View {
    let title: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            WizPathKitHaptics.provider.medium()
            action()
        } label: {
            HStack(spacing: 10) {
                // Vibrant Gradient Icon Background
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: gradientColors.first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 2)

                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.04))
                    
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.15), .white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    WizPathKitHaptics.provider.selectionChanged()
                }
                .onEnded { _ in isPressed = false }
        )
        .animation(AppTheme.pressSpring, value: isPressed)
    }
}

