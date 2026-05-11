import Foundation

public struct WardrobePreferences: Codable, Equatable, Sendable {
    public var hasUmbrella: Bool
    public var hasRaincoat: Bool
    public var hasWinterCoat: Bool
    public var hasSunglasses: Bool
    public var hasGloves: Bool
    public var hasThermals: Bool

    public init(
        hasUmbrella: Bool = true,
        hasRaincoat: Bool = true,
        hasWinterCoat: Bool = true,
        hasSunglasses: Bool = true,
        hasGloves: Bool = true,
        hasThermals: Bool = true
    ) {
        self.hasUmbrella = hasUmbrella
        self.hasRaincoat = hasRaincoat
        self.hasWinterCoat = hasWinterCoat
        self.hasSunglasses = hasSunglasses
        self.hasGloves = hasGloves
        self.hasThermals = hasThermals
    }

    public static var `default`: WardrobePreferences {
        WardrobePreferences()
    }
}
