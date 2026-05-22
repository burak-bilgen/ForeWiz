import SwiftUI
import CoreLocation

// MARK: - Charging Station Detail Sheet

public struct ChargingStationDetailSheet: View {
    let station: SmartStop
    @Environment(\.dismiss) private var dismiss

    public init(station: SmartStop) {
        self.station = station
    }

    private var isTurkish: Bool {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return code.lowercased().hasPrefix("tr")
    }

    public var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
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
                    }

                    // Weather at Arrival Card (if available)
                    if let weather = station.weatherAtArrival {
                        LiquidGlassCard(accentColor: Color(hex: weather.severity.colorHex), innerPadding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "cloud.sun.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: weather.severity.colorHex))
                                    Text(isTurkish ? "Varış Zamanı Hava Durumu" : "Weather at Arrival")
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

                                    Text(weatherConditionDisplay(weather))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                        }
                    }

                    // Weather Advisor Recommendation Card
                    if let recommendation = station.weatherRecommendation {
                        LiquidGlassCard(accentColor: Color(hex: station.safetyStatus.color), innerPadding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: station.safetyStatus.color))
                                    Text(isTurkish ? "Akıllı Yol Danışmanı" : "Smart Route Advisor")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    if station.safetyStatus.shouldAvoid {
                                        Text(isTurkish ? "KAÇININ" : "AVOID")
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
                        }
                    }

                    // Stop Stats Card
                    let stopMins = Int(station.estimatedStopDuration / 60)
                    let stopDurationDisplay = isTurkish ? "\(stopMins) dk" : "\(stopMins) mins"
                    LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 16) {
                        VStack(spacing: 12) {
                            detailRow(icon: "arrow.triangle.swap", label: isTurkish ? "Rotaya Uzaklık" : "Distance from Route", value: formattedDistance(station.distanceFromRoute))
                            detailRow(icon: "clock.fill", label: isTurkish ? "Tahmini Varış (ETA)" : "Estimated Arrival (ETA)", value: station.etaDisplay)
                            detailRow(icon: "hourglass", label: isTurkish ? "Tahmini Bekleme Süresi" : "Estimated Stop Duration", value: stopDurationDisplay)
                        }
                    }

                    // Navigation Action Card
                    LiquidGlassCard(accentColor: Color(hex: station.category.color), innerPadding: 16) {
                        VStack(spacing: 12) {
                            Text(isTurkish ? "Harita uygulamaları üzerinden kolayca navigasyon başlatabilir ve yol tarifi alabilirsiniz." : "You can easily start navigation and get directions using your preferred map application.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 12) {
                                LiquidGlassButton(isTurkish ? "Apple Haritalar" : "Apple Maps", icon: "map.fill", style: .secondary, haptic: .medium) {
                                    openInAppleMaps()
                                }

                                LiquidGlassButton(isTurkish ? "Google Haritalar" : "Google Maps", icon: "arrow.triangle.turn.up.right.diamond.fill", style: .primary, haptic: .medium) {
                                    openInGoogleMaps()
                                }
                            }
                        }
                    }
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

    private func formattedDistance(_ dist: CLLocationDistance) -> String {
        let km = dist / 1000
        return km >= 10 ? "\(Int(km)) km" : String(format: "%.1f km", km)
    }

    private func weatherConditionDisplay(_ weather: SegmentWeather) -> String {
        switch weather.condition {
        case .clear: return isTurkish ? "Açık" : "Clear"
        case .partlyCloudy: return isTurkish ? "Parçalı Bulutlu" : "Partly Cloudy"
        case .cloudy: return isTurkish ? "Bulutlu" : "Cloudy"
        case .rain: return isTurkish ? "Yağmurlu" : "Rain"
        case .heavyRain: return isTurkish ? "Kuvvetli Yağmurlu" : "Heavy Rain"
        case .snow: return isTurkish ? "Karlı" : "Snow"
        case .sleet: return isTurkish ? "Sulu Karlı" : "Sleet"
        case .thunderstorm: return isTurkish ? "Gök Gürültülü" : "Thunderstorm"
        case .fog: return isTurkish ? "Sisli" : "Fog"
        case .windy: return isTurkish ? "Rüzgârlı" : "Windy"
        case .unknown: return isTurkish ? "Bilinmeyen" : "Unknown"
        }
    }

    private func openInAppleMaps() {
        let lat = station.coordinate.latitude
        let lon = station.coordinate.longitude
        let defaultName = station.category.defaultName
        let name = station.displayTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? defaultName
        let url = URL(string: "maps://?q=\(name)&ll=\(lat),\(lon)&z=14")!
        let webURL = URL(string: "https://maps.apple.com/?q=\(name)&ll=\(lat),\(lon)&z=14")!
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }

    private func openInGoogleMaps() {
        let lat = station.coordinate.latitude
        let lon = station.coordinate.longitude
        let appURL = URL(string: "comgooglemaps://?q=\(lat),\(lon)&zoom=14")!
        let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(lat),\(lon)")!
        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}
