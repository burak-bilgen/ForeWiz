import SwiftUI

#Preview {
    ZStack {
        LiquidOrbBackground(palette: .clearSky)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Text(L10n.text("preview_liquid_glass_animations"))
                .font(.title)
                .foregroundStyle(.white)

            PulsingDotsLoader()
                .floating(amplitude: 6, duration: 3)
        }
    }
}
