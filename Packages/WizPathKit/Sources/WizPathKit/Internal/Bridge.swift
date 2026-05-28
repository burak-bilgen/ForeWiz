import Foundation
import CoreLocation
import OSLog
import SwiftUI

// MARK: - L10n Bridge (same API as main app)

public enum WizPathKitL10n {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _provider: WizPathL10nProvider = DefaultL10nProvider()

    public static var provider: WizPathL10nProvider {
        get {
            lock.lock(); defer { lock.unlock() }
            return _provider
        }
        set {
            lock.lock(); defer { lock.unlock() }
            _provider = newValue
        }
    }

    public static func text(_ key: String) -> String {
        provider.text(key)
    }

    public static func formatted(_ key: String, _ arguments: CVarArg...) -> String {
        provider.formatted(key, arguments)
    }
}

public protocol WizPathL10nProvider {
    func text(_ key: String) -> String
    func formatted(_ key: String, _ arguments: [CVarArg]) -> String
}

public struct DefaultL10nProvider: WizPathL10nProvider {
    public init() {}
    public func text(_ key: String) -> String { key }
    public func formatted(_ key: String, _ arguments: [CVarArg]) -> String {
        String(format: key, arguments: arguments)
    }
}

// MARK: - Logger Bridge

public enum WizPathKitLogger {
    public static let wizPath = Logger(subsystem: "com.forewiz.wizpath", category: "wizpath")
    public static let search = Logger(subsystem: "com.forewiz.wizpath", category: "search")
    public static let analytics = Logger(subsystem: "com.forewiz.wizpath", category: "analytics")
    public static let notifications = Logger(subsystem: "com.forewiz.wizpath", category: "notifications")
}

typealias AppLogger = WizPathKitLogger
typealias L10n = WizPathKitL10n

// MARK: - Haptic Bridge

public protocol WizPathHapticProvider {
    func light()
    func medium()
    func success()
    func warning()
    func error()
    func heavy()
    func selectionChanged()
    func weatherRefresh()
}

final class HapticEngine: Sendable {
    public static let shared = HapticEngine()
    private init() {}

    public func light() { WizPathKitHaptics.provider.light() }
    public func medium() { WizPathKitHaptics.provider.medium() }
    public func heavy() { WizPathKitHaptics.provider.heavy() }
    public func success() { WizPathKitHaptics.provider.success() }
    public func warning() { WizPathKitHaptics.provider.warning() }
    public func error() { WizPathKitHaptics.provider.error() }
    public func selectionChanged() { WizPathKitHaptics.provider.selectionChanged() }
    public func weatherRefresh() { WizPathKitHaptics.provider.weatherRefresh() }
}

public enum WizPathKitHaptics {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _provider: WizPathHapticProvider = DefaultHapticProvider()

    public static var provider: WizPathHapticProvider {
        get {
            lock.lock(); defer { lock.unlock() }
            return _provider
        }
        set {
            lock.lock(); defer { lock.unlock() }
            _provider = newValue
        }
    }
}

public struct DefaultHapticProvider: WizPathHapticProvider {
    public init() {}
    public func light() {}
    public func medium() {}
    public func heavy() {}
    public func success() {}
    public func warning() {}
    public func error() {}
    public func selectionChanged() {}
    public func weatherRefresh() {}
}

// MARK: - Formatters Bridge

public enum WizPathKitFormatters {
    public static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Formats a distance in meters to a localized human-readable string.
    /// - Distances >= 1 km: "2.5 km" or "10 km"
    /// - Distances < 1 km: "800m"
    public static func formattedDistance(_ dist: CLLocationDistance) -> String {
        let km = dist / 1000
        if km >= 1 {
            let unit = WizPathKitL10n.text("unit_km")
            if km >= 10 {
                return "\(Int(km)) \(unit)"
            }
            return String(format: "%.1f %@", locale: Locale.current, km as CVarArg, unit)
        }
        let unit = WizPathKitL10n.text("unit_m")
        return "\(Int(dist))\(unit)"
    }
}

typealias SharedFormatters = WizPathKitFormatters

// MARK: - App Keys Bridge

public enum WizPathKitKeys {
    public enum UserDefaults {
        public static let wizPathRecentDestinations = "wizpath_recent_destinations"
    }
}

typealias AppKeys = WizPathKitKeys

// MARK: - App Theme Bridge (colors + animations used by WizPath views)

@available(iOS 17.0, *)
extension Color {
    public static let liquidAccent = Color(red: 0.25, green: 0.60, blue: 1.0)
    public static let success = Color(red: 0.18, green: 0.70, blue: 0.48)
    public static let warning = Color(red: 0.95, green: 0.62, blue: 0.18)
    public static let danger = Color(red: 0.92, green: 0.28, blue: 0.32)
    public static let teal = Color(red: 0.15, green: 0.75, blue: 0.68)
    public static let royalPurple = Color(red: 0.55, green: 0.35, blue: 0.95)
    public static let coral = Color(red: 1.0, green: 0.40, blue: 0.40)
    public static let liquidAccentSoft = Color(red: 0.45, green: 0.75, blue: 1.0)

    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@available(iOS 17.0, *)
enum AppTheme {
    // Animation tokens
    public static let pressSpring: Animation = .spring(response: 0.22, dampingFraction: 0.72)
    public static let cardSpring: Animation = .spring(response: 0.38, dampingFraction: 0.82)
    public static let transitionSpring: Animation = .spring(response: 0.48, dampingFraction: 0.85)
    public static let sheetSpring: Animation = .spring(response: 0.6, dampingFraction: 0.8)
    public static let slowEaseOut: Animation = .easeOut(duration: 0.55)
    public static let defaultEaseOut: Animation = .easeOut(duration: 0.35)
    public static let pulseEaseOut: Animation = .easeInOut(duration: 1.0)
    public static let quickEaseOut: Animation = .easeOut(duration: 0.2)
    public static let staggerDelay: Double = 0.05
    public static let defaultDelay: Double = 0.08

    // Route risk color mapping
    public static func routeRiskColor(_ risk: RouteRisk) -> Color {
        switch risk {
        case .good: return .success
        case .caution: return .warning
        case .severe: return .danger
        }
    }

    // Ambient gradient
    public static func ambientGradient(for colorScheme: ColorScheme = .dark) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.10),
                Color(red: 0.06, green: 0.08, blue: 0.14),
                Color(red: 0.03, green: 0.04, blue: 0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - External Repository Protocols

public struct WizPathCoordinate: Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public protocol WizPathWeatherSource: AnyObject, Sendable {
    func fetchWeather(for coordinate: WizPathCoordinate) async throws -> WizPathWeatherSnapshot
}

public protocol WizPathLocationSource: AnyObject, Sendable {
    func getCurrentLocation() async throws -> WizPathCoordinate
}

// MARK: - Weather Snapshot (minimal required subset)

public struct WizPathWeatherSnapshot: Sendable {
    public let current: WizPathCurrentWeather
    public let hourly: [WizPathHourlyForecast]
    public let daily: [WizPathDailyForecast]

    public init(current: CurrentWeather, hourly: [HourlyForecast], daily: [DailyForecast]) {
        self.current = current
        self.hourly = hourly
        self.daily = daily
    }
}

public typealias CurrentWeather = WizPathCurrentWeather
public typealias HourlyForecast = WizPathHourlyForecast
public typealias DailyForecast = WizPathDailyForecast

public struct WizPathCurrentWeather: Sendable {
    public let temperatureCelsius: Double
    public let conditionCode: String?
    public let symbolName: String?
    public let precipitationChance: Double?
    public let windSpeedKph: Double?

    public init(temperatureCelsius: Double, conditionCode: String? = nil, symbolName: String? = nil,
                precipitationChance: Double? = nil, windSpeedKph: Double? = nil) {
        self.temperatureCelsius = temperatureCelsius
        self.conditionCode = conditionCode
        self.symbolName = symbolName
        self.precipitationChance = precipitationChance
        self.windSpeedKph = windSpeedKph
    }
}

public struct WizPathHourlyForecast: Sendable {
    public let date: Date
    public let temperatureCelsius: Double
    public let conditionCode: String?
    public let symbolName: String?
    public let precipitationChance: Double?
    public let windSpeedKph: Double?

    public init(date: Date, temperatureCelsius: Double, conditionCode: String? = nil, symbolName: String? = nil,
                precipitationChance: Double? = nil, windSpeedKph: Double? = nil) {
        self.date = date
        self.temperatureCelsius = temperatureCelsius
        self.conditionCode = conditionCode
        self.symbolName = symbolName
        self.precipitationChance = precipitationChance
        self.windSpeedKph = windSpeedKph
    }
}

public struct WizPathDailyForecast: Sendable {
    public let date: Date
    public let highCelsius: Double
    public let lowCelsius: Double
    public let conditionCode: String?
    public let symbolName: String?

    public init(date: Date, highCelsius: Double, lowCelsius: Double, conditionCode: String? = nil, symbolName: String? = nil) {
        self.date = date
        self.highCelsius = highCelsius
        self.lowCelsius = lowCelsius
        self.conditionCode = conditionCode
        self.symbolName = symbolName
    }
}

// MARK: - Mock Repository (for previews)

public final class MockWizPathWeatherSource: WizPathWeatherSource, @unchecked Sendable {
    public init() {}
    public func fetchWeather(for coordinate: WizPathCoordinate) async throws -> WizPathWeatherSnapshot {
        WizPathWeatherSnapshot(
            current: WizPathCurrentWeather(temperatureCelsius: 22, conditionCode: "clear", symbolName: "sun.max", precipitationChance: 0.1, windSpeedKph: 12),
            hourly: (0..<24).map { h in
                WizPathHourlyForecast(date: Date().addingTimeInterval(Double(h) * 3600), temperatureCelsius: 18 + Double(h % 8), conditionCode: "clear", symbolName: "sun.max", precipitationChance: 0.1, windSpeedKph: 10)
            },
            daily: (0..<7).map { d in
                WizPathDailyForecast(date: Date().addingTimeInterval(Double(d) * 86400), highCelsius: 25, lowCelsius: 15, conditionCode: "clear", symbolName: "sun.max")
            }
        )
    }
}

public final class MockWizPathLocationSource: WizPathLocationSource, @unchecked Sendable {
    public init() {}
    public func getCurrentLocation() async throws -> WizPathCoordinate {
        WizPathCoordinate(latitude: 41.0082, longitude: 28.9784)
    }
}

// MARK: - Liquid Glass Card (premium glass morphism)

public struct LiquidGlassCard<Content: View>: View {
    let accentColor: Color
    let isInteractive: Bool
    let innerPadding: CGFloat
    let cornerRadius: CGFloat
    let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var sheenOffset: CGFloat = -1.5

    public init(accentColor: Color = .liquidAccent, isInteractive: Bool = false, innerPadding: CGFloat = 16, cornerRadius: CGFloat = 22,
                @ViewBuilder content: () -> Content) {
        self.accentColor = accentColor
        self.isInteractive = isInteractive
        self.innerPadding = innerPadding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(innerPadding)
            .background(
                ZStack {
                    // 1. Base glass layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)

                    // 2. Neutral gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [.white.opacity(0.03), .clear, .white.opacity(0.01), .clear]
                                    : [.white.opacity(0.06), .clear, .white.opacity(0.02), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // 3. Animated sheen
                    if !reduceMotion {
                        LiquidCardSheen(cornerRadius: cornerRadius, accentColor: accentColor, offset: sheenOffset)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true).delay(1.0)) {
                                    sheenOffset = 1.5
                                }
                            }
                    }

                    // 3b. Static shimmer for reduced motion
                    if reduceMotion {
                        LiquidCardSheen(cornerRadius: cornerRadius, accentColor: accentColor, offset: 0.5)
                    }

                    // 4. Cool border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [.white.opacity(0.10), .white.opacity(0.02), .white.opacity(0.05), .clear, .white.opacity(0.03), .white.opacity(0.07)]
                                    : [.white.opacity(0.20), .white.opacity(0.04), .white.opacity(0.10), .clear, .white.opacity(0.05), .white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )

                    // 5. Accent rim
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(accentColor.opacity(colorScheme == .dark ? 0.08 : 0.12), lineWidth: 0.5)

                    // 6. Depth shadow
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.black.opacity(0.20), lineWidth: 1.5)
                        .blur(radius: 0.5)
                        .offset(x: 0, y: 1.5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Card Sheen Layer

private struct LiquidCardSheen: View {
    let cornerRadius: CGFloat
    let accentColor: Color
    let offset: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(colorScheme == .dark ? 0.03 : 0.06),
                    accentColor.opacity(colorScheme == .dark ? 0.04 : 0.06),
                    .white.opacity(colorScheme == .dark ? 0.02 : 0.04),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 1.6)
            .offset(x: offset * geo.size.width * 0.8)
            .blendMode(.plusLighter)
        }
    }
}

// MARK: - Destination Flag (used by map views)

public struct DestinationFlag: View {
    @State private var bounce = false

    public init() {}

    public var body: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 28))
            .foregroundStyle(Color.liquidAccent, .white)
            .background(Circle().fill(.white).frame(width: 8, height: 8))
            .scaleEffect(bounce ? 1.1 : 1.0)
            .animation(AppTheme.pulseEaseOut.repeatForever(autoreverses: true), value: bounce)
            .onAppear { bounce = true }
    }
}

// MARK: - App Background (for previews)

public struct AppBackground: View {
    public init() {}
    public var body: some View {
        AppTheme.ambientGradient(for: .dark).ignoresSafeArea()
    }
}

// MARK: - Liquid Glass Button (premium glass button with haptics)

public struct LiquidGlassButton: View {
    let title: String?
    let icon: String?
    let style: LiquidGlassButtonStyle
    let haptic: LiquidHapticStyle
    let isFullWidth: Bool
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    public init(_ title: String? = nil, icon: String? = nil, style: LiquidGlassButtonStyle = .secondary,
                haptic: LiquidHapticStyle = .light, isFullWidth: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.haptic = haptic
        self.isFullWidth = isFullWidth
        self.action = action
    }

    public var body: some View {
        Button {
            if isEnabled {
                haptic.trigger()
                action()
            }
        } label: {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(style.accentColor)
                }
                if let title = title {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(style == .tertiary ? .white.opacity(0.65) : .white)
                }
            }
            .frame(minWidth: 44, minHeight: 44)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, title != nil ? (isFullWidth ? 4 : 18) : 14)
            .padding(.vertical, 12)
            .background(glassBackground)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.4)
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    if !reduceMotion {
                        HapticEngine.shared.selectionChanged()
                    }
                }
                .onEnded { _ in isPressed = false }
        )
        .animation(AppTheme.pressSpring, value: isPressed)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(style.accentColor.opacity(style.backgroundOpacity))
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.18), style.accentColor.opacity(0.08), .clear],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
            if style.hasSheen && !reduceMotion {
                LiquidButtonSheen(accent: style.accentColor)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var accessibilityLabel: String {
        [title, icon].compactMap { $0 }.joined(separator: ", ")
    }
}

public enum LiquidGlassButtonStyle {
    case primary
    case secondary
    case tertiary
    case danger

    var accentColor: Color {
        switch self {
        case .primary: return .liquidAccent
        case .secondary: return .liquidAccentSoft
        case .tertiary: return .white.opacity(0.6)
        case .danger: return .coral
        }
    }

    var backgroundOpacity: Double {
        switch self {
        case .primary: return 0.20
        case .secondary: return 0.10
        case .tertiary: return 0.04
        case .danger: return 0.18
        }
    }

    var hasSheen: Bool { self == .primary }
}

public enum LiquidHapticStyle {
    case light, medium, heavy, selection, success, none

    public func trigger() {
        switch self {
        case .light: HapticEngine.shared.light()
        case .medium: HapticEngine.shared.medium()
        case .heavy: HapticEngine.shared.heavy()
        case .selection: HapticEngine.shared.selectionChanged()
        case .success: HapticEngine.shared.success()
        case .none: break
        }
    }
}

private struct LiquidButtonSheen: View {
    let accent: Color
    @State private var offset: CGFloat = -1.0

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, accent.opacity(0.12), .white.opacity(0.06), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.6)
            .offset(x: offset * (geo.size.width + geo.size.width * 0.6))
            .blendMode(.plusLighter)
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false).delay(0.5)) {
                    offset = 1.0
                }
            }
        }
        .clipped()
    }
}


