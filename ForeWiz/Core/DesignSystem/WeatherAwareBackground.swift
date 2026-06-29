import SwiftUI

struct WeatherAwareBackground: View {
    @ObservedObject private var service = WeatherGradientService.shared
    let condition: String?
    let isDaylight: Bool?
    let temperature: Double?
    let decision: OutdoorDecision?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let gradientSet = service.gradientFor(
            condition: condition,
            isDaylight: isDaylight,
            temperature: temperature,
            decision: decision,
            colorScheme: colorScheme
        )

        ZStack {
            gradientSet.primary
                .ignoresSafeArea()

            if let secondary = gradientSet.secondary {
                secondary
                    .ignoresSafeArea()
                    .opacity(0.5)
            }
        }
        .animation(.easeInOut(duration: 2.0), value: condition)
    }
}
