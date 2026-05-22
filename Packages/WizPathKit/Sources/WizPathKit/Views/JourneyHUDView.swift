import SwiftUI
import CoreLocation

// MARK: - Journey HUD View

public struct JourneyHUDView: View {
    let data: JourneyHUDData
    @State private var isExpanded = false

    public init(data: JourneyHUDData) { self.data = data }

    public var body: some View {
        VStack(spacing: 0) {
            LiquidGlassCard(accentColor: safetyTint, innerPadding: 0, cornerRadius: 16) {
                HStack(spacing: 0) {
                    ZStack { Circle().fill(safetyTint.opacity(0.15)).frame(width: 32, height: 32); Image(systemName: safetyIcon).font(.system(size: 14, weight: .bold)).foregroundStyle(safetyTint) }.padding(.leading, 12)
                    HStack(spacing: 0) {
                        StatItem(value: data.durationDisplay, label: WizPathKitL10n.text("hud_eta"), color: .white)
                        Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 20).padding(.horizontal, 8)
                        StatItem(value: "\(data.hazardCount)", label: WizPathKitL10n.text("hud_hazards"), color: data.hazardCount > 0 ? .warning : .secondary)
                        Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 20).padding(.horizontal, 8)
                        StatItem(value: "\(data.safetyScore)", label: WizPathKitL10n.text("hud_safety"), color: safetyTint)
                    }.padding(.horizontal, 8)
                    Spacer(minLength: 0)
                    Button { withAnimation(AppTheme.cardSpring) { isExpanded.toggle(); HapticEngine.shared.light() } } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down").font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary).frame(width: 26, height: 26).background(Color.white.opacity(0.06)).clipShape(Circle())
                    }.contentShape(Rectangle()).buttonStyle(.plain).padding(.trailing, 10)
                }.padding(.vertical, 10)
            }
            if isExpanded {
                HUDDetailPanel(safetyScore: data.safetyScore, hazards: data.activeHazards, nextSafeStop: data.nextSafeStop)
                    .transition(.move(edge: .top).combined(with: .opacity)).padding(.top, 6)
            }
        }
    }

    private var safetyTint: Color {
        switch data.safetyScore { case 80...100: return .success; case 60..<80: return .liquidAccent; case 40..<60: return .warning; default: return .danger }
    }

    private var safetyIcon: String {
        switch data.safetyScore { case 80...100: return "checkmark.shield.fill"; case 60..<80: return "shield.fill"; case 40..<60: return "exclamationmark.shield.fill"; default: return "xmark.shield.fill" }
    }
}

// MARK: - Stat Item

public struct StatItem: View {
    let value: String; let label: String; let color: Color
    public init(value: String, label: String, color: Color) { self.value = value; self.label = label; self.color = color }
    public var body: some View {
        VStack(spacing: 1) {
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(color).monospacedDigit()
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.tertiary)
        }
    }
}

// MARK: - HUD Detail Panel

public struct HUDDetailPanel: View {
    let safetyScore: Int; let hazards: [EnvironmentalHazard]; let nextSafeStop: SmartStop?

    public init(safetyScore: Int, hazards: [EnvironmentalHazard], nextSafeStop: SmartStop?) {
        self.safetyScore = safetyScore; self.hazards = hazards; self.nextSafeStop = nextSafeStop
    }

    public var body: some View {
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 14, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                safetyScoreBar
                if !hazards.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 12)).foregroundStyle(Color.warning)
                            Text(hazards.count == 1 ? WizPathKitL10n.text("hud_active_hazard_singular") : WizPathKitL10n.formatted("hud_active_hazard_plural", hazards.count)).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.warning)
                        }
                        ForEach(hazards.prefix(3)) { hazard in HazardRow(hazard: hazard) }
                        if hazards.count > 3 { Text(WizPathKitL10n.formatted("hud_more", hazards.count - 3)).font(.caption).foregroundStyle(.tertiary) }
                    }.padding(10).background(Color.warning.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                if let stop = nextSafeStop { nextStopCard(stop) }
            }
        }
    }

    private func nextStopCard(_ stop: SmartStop) -> some View {
        HStack(spacing: 10) {
            Circle().fill(Color.success.opacity(0.12)).frame(width: 32, height: 32).overlay(Image(systemName: stop.category.iconName).font(.system(size: 14)).foregroundStyle(Color(hex: stop.category.color)))
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.displayTitle).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                HStack(spacing: 8) {
                    Label(stop.etaDisplay, systemImage: "clock").font(.caption).foregroundStyle(.tertiary)
                    if let weather = stop.weatherAtArrival { Label("\(Int(weather.temperature))°", systemImage: weather.iconName).font(.caption).foregroundStyle(.tertiary) }
                }
            }
            Spacer()
            Text(stop.safetyStatus.localizedTitle).font(.system(size: 9, weight: .semibold)).foregroundStyle(Color(hex: stop.safetyStatus.color)).padding(.horizontal, 6).padding(.vertical, 2).background(Color(hex: stop.safetyStatus.color).opacity(0.12)).clipShape(Capsule())
        }.padding(10).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var safetyScoreBar: some View {
        VStack(spacing: 6) {
            HStack {
                Label(WizPathKitL10n.text("hud_journey_safety"), systemImage: "shield.checkered").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
                Text(safetyRatingText).font(.system(size: 11, weight: .bold)).foregroundStyle(safetyScoreColor)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.06)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(safetyScoreColor).frame(width: geometry.size.width * (Double(safetyScore) / 100.0), height: 6).animation(AppTheme.sheetSpring, value: safetyScore)
                }
            }.frame(height: 6)
        }
    }

    private var safetyRatingText: String {
        switch safetyScore { case 80...100: return WizPathKitL10n.text("hud_rating_excellent"); case 60..<80: return WizPathKitL10n.text("hud_rating_good"); case 40..<60: return WizPathKitL10n.text("hud_rating_moderate"); case 20..<40: return WizPathKitL10n.text("hud_rating_poor"); default: return WizPathKitL10n.text("hud_rating_dangerous") }
    }

    private var safetyScoreColor: Color {
        switch safetyScore { case 80...100: return .success; case 60..<80: return .liquidAccent; case 40..<60: return .warning; default: return .danger }
    }
}

// MARK: - Hazard Row

public struct HazardRow: View {
    let hazard: EnvironmentalHazard
    public init(hazard: EnvironmentalHazard) { self.hazard = hazard }

    public var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(hex: hazard.severity.color)).frame(width: 6, height: 6)
            Image(systemName: hazard.iconName).font(.system(size: 11)).foregroundStyle(Color(hex: hazard.severity.color)).frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(hazard.localizedTitle).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                Text(WizPathKitL10n.formatted("hud_at_time", WizPathKitFormatters.shortTime.string(from: hazard.etaAtLocation))).font(.caption).foregroundStyle(.tertiary)
            }
            Spacer()
            Text(hazard.severity.localizedTitle).font(.system(size: 8, weight: .semibold)).foregroundStyle(Color(hex: hazard.severity.color)).padding(.horizontal, 4).padding(.vertical, 1).background(Color(hex: hazard.severity.color).opacity(0.12)).clipShape(Capsule())
        }
    }
}
