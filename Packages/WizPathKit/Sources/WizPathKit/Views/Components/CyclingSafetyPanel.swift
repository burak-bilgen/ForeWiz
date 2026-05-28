import SwiftUI

// MARK: - Cycling Safety Panel

public struct CyclingSafetyPanel: View {
    let safety: WizPathCyclingSafetyService.CyclingSafetyAnalysis

    public init(safety: WizPathCyclingSafetyService.CyclingSafetyAnalysis) {
        self.safety = safety
    }

    public var body: some View {
        LiquidGlassCard(accentColor: accentColor, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "bicycle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accentColor)
                    Text(WizPathKitL10n.text("wizpath_cycling_safety_title"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    safetyBadge
                }

                // Effort level
                effortRow

                // Wind details
                if safety.hasCrosswindRisk || safety.hasSignificantHeadwind {
                    windDetailsRow
                }

                // Crosswind segments
                if !safety.crosswindSegments.isEmpty {
                    crosswindWarning
                }

                // Safety recommendation
                if !safety.safety.isSafe {
                    recommendationRow
                }
            }
        }
    }

    @ViewBuilder
    private var safetyBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(accentColor)
                .frame(width: 6, height: 6)
            Text(safety.safety.isSafe ? WizPathKitL10n.text("wizpath_cycling_badge_safe") : (safety.safety.isRisky ? WizPathKitL10n.text("wizpath_cycling_badge_caution") : WizPathKitL10n.text("wizpath_cycling_badge_not_recommended")))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accentColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(accentColor.opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var effortRow: some View {
        HStack(spacing: 10) {
            // Effort meter
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 36, height: 36)
                Circle()
                    .trim(from: 0, to: CGFloat(safety.effortLevel.level) / 10.0)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                Text(verbatim: "\(safety.effortLevel.level)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(WizPathKitL10n.text("wizpath_cycling_effort_level"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(safety.effortLevel.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if safety.effortLevel.extraTimePercent > 0 {
                    Text(WizPathKitL10n.formatted("wizpath_cycling_extra_time", safety.effortLevel.extraTimePercent))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var windDetailsRow: some View {
        HStack(spacing: 16) {
            // Wind speed
            VStack(spacing: 2) {
                Image(systemName: "wind")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text(verbatim: "\(Int(safety.overallWindSpeed))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(WizPathKitL10n.text("wizpath_unit_kmh"))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)

            // Gust
            VStack(spacing: 2) {
                Image(systemName: "wind.snow")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text(verbatim: "\(Int(safety.maxGustSpeed))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(WizPathKitL10n.text("wizpath_unit_gust"))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)

            // Crosswind segments
            if safety.hasCrosswindRisk {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#FF9500"))
                    Text(verbatim: "\(safety.crosswindSegments.count)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(WizPathKitL10n.text("wizpath_cycling_crosswind_short"))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var crosswindWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#FF9500"))
            Text(WizPathKitL10n.formatted(safety.crosswindSegments.count > 1 ? "wizpath_cycling_crosswind_segments_plural" : "wizpath_cycling_crosswind_segments_singular", safety.crosswindSegments.count))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color(hex: "#FF9500").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var recommendationRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(accentColor)
            Text(recommendationText)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var recommendationText: String {
        switch safety.safety {
        case .notRecommended(let reason):
            return reason
        case .caution(let reason):
            return reason
        case .safe:
            return WizPathKitL10n.text("wizpath_cycling_safe_conditions")
        }
    }

    private var accentColor: Color {
        switch safety.safety {
        case .safe: return .green
        case .caution: return .orange
        case .notRecommended: return .red
        }
    }
}
