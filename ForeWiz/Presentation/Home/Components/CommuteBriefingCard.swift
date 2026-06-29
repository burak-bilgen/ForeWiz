import SwiftUI
import WizPathKit

struct CommuteBriefingCard: View {
    let briefing: CommuteBriefing
    let homeName: String
    let workName: String
    let travelMode: TravelMode
    let onEditLocations: () -> Void

    @State private var isExpanded = false
    @State private var rotationAngle = 0.0

    private var score: Int {
        if briefing.routeHazards.isEmpty {
            return 85
        }
        return max(40, 100 - briefing.routeHazards.count * 12)
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return AppTheme.success
        case 50..<80: return AppTheme.sunshine
        default: return AppTheme.warning
        }
    }

    var body: some View {
        LiquidGlassCard(accentColor: scoreColor, innerPadding: 0) {
            VStack(spacing: 0) {

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                        HapticEngine.shared.light()
                    }
                } label: {
                    HStack(spacing: 14) {

                        ZStack {
                            Circle()
                                .fill(scoreColor.opacity(0.18))
                                .frame(width: 44, height: 44)

                            Image(systemName: travelMode.iconName)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(scoreColor)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Text(homeName)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .lineLimit(1)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.3))
                                Text(workName)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            Text(briefing.summary)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }

                        Spacer(minLength: 8)

                        ZStack {
                            Circle()
                                .stroke(scoreColor.opacity(0.2), lineWidth: 3)
                                .frame(width: 40, height: 40)
                            Circle()
                                .trim(from: 0, to: CGFloat(score) / 100)
                                .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                            Text("\(score)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(scoreColor)
                        }

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.3))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()
                        .background(.white.opacity(0.06))
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {

                        VStack(spacing: 8) {
                            briefRow(
                                icon: "house.fill",
                                label: L10n.text("settings_home_location"),
                                value: briefing.weatherAtOrigin
                            )
                            briefRow(
                                icon: "briefcase.fill",
                                label: L10n.text("settings_work_location"),
                                value: briefing.weatherAtDestination
                            )
                        }

                        if !briefing.routeHazards.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label {
                                    Text(L10n.text("alert_warning"))
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                } icon: {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(AppTheme.warning)

                                ForEach(briefing.routeHazards, id: \.self) { hazard in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(AppTheme.warning)
                                            .frame(width: 4, height: 4)
                                        Text(hazard)
                                            .font(.system(size: 11, weight: .regular, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.6))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(10)
                            .background(AppTheme.warning.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(scoreColor)
                            Text(briefing.recommendation)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            HapticEngine.shared.light()
                            onEditLocations()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 10))
                                Text(L10n.text("action_change"))
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    AngularGradient(
                        colors: [scoreColor.opacity(0.3), .clear, scoreColor.opacity(0.3), .clear, scoreColor.opacity(0.3)],
                        center: .center,
                        angle: .degrees(rotationAngle)
                    ),
                    lineWidth: 0.8
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360.0
            }
        }
    }

    @ViewBuilder
    private func briefRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36, maxHeight: 44, alignment: .leading)
        .clipped()
        .padding(10)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 16) {
                CommuteBriefingCard(
                    briefing: CommuteBriefing(
                        summary: "Good commute conditions for car. 12.5 km, approximately 20 min.",
                        weatherAtOrigin: "22°C, partly cloudy",
                        weatherAtDestination: "26°C, sunny",
                        routeHazards: [],
                        recommendation: "Optimal conditions — proceed as planned."
                    ),
                    homeName: "Home",
                    workName: "Work",
                    travelMode: .car,
                    onEditLocations: {}
                )

                CommuteBriefingCard(
                    briefing: CommuteBriefing(
                        summary: "Moderate commute conditions for cycling. 8.3 km, approximately 35 min. Some weather factors to consider.",
                        weatherAtOrigin: "18°C, light rain",
                        weatherAtDestination: "20°C, cloudy",
                        routeHazards: [
                            "High wind sensitivity for cycling. Gusts could affect stability.",
                            "Long commute (8.3 km) — weather conditions may vary significantly along the route."
                        ],
                        recommendation: "Consider departing early morning to avoid peak heat."
                    ),
                    homeName: "Kadıköy",
                    workName: "Levent",
                    travelMode: .cycling,
                    onEditLocations: {}
                )
            }
            .padding()
        }
    }
}
