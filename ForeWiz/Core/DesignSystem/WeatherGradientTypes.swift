import SwiftUI

// MARK: - Gradient Set

struct WeatherGradientSet {
    let primary: LinearGradient
    let secondary: LinearGradient?
    let accent: Color
    let particleEffect: ParticleEffect?
    let animationSpeed: Double

    static let `default` = WeatherGradientSet(
        primary: LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        ),
        secondary: nil,
        accent: .blue,
        particleEffect: nil,
        animationSpeed: 1.0
    )
}

// MARK: - Particle Effect

enum ParticleEffect: Equatable {
    case rain(Intensity: Double)
    case snow(Intensity: Double)
    case clouds(Density: Double)
    case stars(Count: Int)
    case sunRays(Intensity: Double)
}


