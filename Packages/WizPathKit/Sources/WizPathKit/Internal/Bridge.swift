import Foundation
import OSLog
import SwiftUI

// MARK: - L10n Bridge (same API as main app)

public enum WizPathKitL10n {
    nonisolated(unsafe) public static var provider: WizPathL10nProvider = DefaultL10nProvider()

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

final class HapticEngine {
    nonisolated(unsafe) public static let shared = HapticEngine()
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
    nonisolated(unsafe) public static var provider: WizPathHapticProvider = DefaultHapticProvider()
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

// MARK: - Liquid Glass Card (used by views)

public struct LiquidGlassCard<Content: View>: View {
    let accentColor: Color
    let innerPadding: CGFloat
    let cornerRadius: CGFloat
    let content: Content

    public init(accentColor: Color = .liquidAccent, innerPadding: CGFloat = 14, cornerRadius: CGFloat = 20,
                @ViewBuilder content: () -> Content) {
        self.accentColor = accentColor
        self.innerPadding = innerPadding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(innerPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            )
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

// MARK: - Liquid Glass Button (used by route info panel)

public struct LiquidGlassButton: View {
    let title: String?
    let icon: String?
    let style: LiquidGlassButtonStyle
    let haptic: LiquidHapticStyle
    let isFullWidth: Bool
    let action: () -> Void

    @State private var isPressed = false

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
            haptic.trigger()
            action()
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
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    HapticEngine.shared.selectionChanged()
                }
                .onEnded { _ in isPressed = false }
        )
        .animation(AppTheme.pressSpring, value: isPressed)
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
            if style.hasSheen {
                LiquidButtonSheen(accent: style.accentColor)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    func trigger() {
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

// MARK: - Flow Layout (used by some views)

public struct FlowLayout: Layout {
    public let spacing: CGFloat

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                y += size.height + spacing
                x = 0
            }
            x += size.width + spacing
            height = max(height, y + size.height)
        }

        return CGSize(width: maxWidth, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                y += size.height + spacing
                x = bounds.minX
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
        }
    }
}
