import SwiftUI

// MARK: - Route Comparison Card

public struct RouteComparisonCard: View {
    let candidates: [ScoredRouteCandidate]
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    let onClose: () -> Void

    public init(candidates: [ScoredRouteCandidate], selectedIndex: Int,
                onSelect: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        self.candidates = candidates
        self.selectedIndex = selectedIndex
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 16) {
            VStack(spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.liquidAccent)
                    Text(WizPathKitL10n.text("wizpath_route_comparison"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        HapticEngine.shared.light()
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Legend
                HStack(spacing: 12) {
                    legendDot(color: .success, label: WizPathKitL10n.text("route_score_best"))
                    legendDot(color: Color(hex: "#30D158"), label: WizPathKitL10n.text("route_score_good"))
                    legendDot(color: Color(hex: "#FFCC00"), label: WizPathKitL10n.text("route_score_moderate"))
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

                // Candidate rows
                ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                    RouteCandidateRow(
                        index: index,
                        candidate: candidate,
                        isSelected: index == selectedIndex,
                        isFirst: index == 0
                    ) {
                        onSelect(index)
                    }
                }

                // Info footer
                Text(WizPathKitL10n.text("wizpath_route_comparison_footer"))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }
}

// MARK: - Route Candidate Row

public struct RouteCandidateRow: View {
    let index: Int
    let candidate: ScoredRouteCandidate
    let isSelected: Bool
    let isFirst: Bool
    let action: () -> Void

    @State private var isPressed = false

    public init(index: Int, candidate: ScoredRouteCandidate, isSelected: Bool,
                isFirst: Bool, action: @escaping () -> Void) {
        self.index = index
        self.candidate = candidate
        self.isSelected = isSelected
        self.isFirst = isFirst
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(candidate.isBest ? Color.success.opacity(0.2) :
                              candidate.isGood ? Color(hex: candidate.scoreColorHex).opacity(0.15) :
                              Color(hex: candidate.scoreColorHex).opacity(0.1))
                        .frame(width: 32, height: 32)
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: candidate.scoreColorHex))
                }

                // Route info
                VStack(alignment: .leading, spacing: 2) {
                    // Duration + Distance
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(candidate.formattedDuration)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 9))
                        Text(candidate.formattedDistance)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    // Badges: Traffic + Toll + Weather
                    HStack(spacing: 6) {
                        // Traffic badge
                        if candidate.trafficCongestion != .unknown {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color(hex: candidate.trafficCongestion.colorHex))
                                    .frame(width: 5, height: 5)
                                Text(candidate.trafficCongestion.localizedTitle)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(Color(hex: candidate.trafficCongestion.colorHex))
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(hex: candidate.trafficCongestion.colorHex).opacity(0.12))
                            .clipShape(Capsule())
                        }

                        // Toll badge
                        if candidate.hasTollRoads {
                            HStack(spacing: 2) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 7))
                                Text(WizPathKitL10n.text("route_label_toll"))
                                    .font(.system(size: 8, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: "#FF9500"))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(hex: "#FF9500").opacity(0.12))
                            .clipShape(Capsule())
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 7))
                                Text(WizPathKitL10n.text("route_label_free"))
                                    .font(.system(size: 8, weight: .medium))
                            }
                            .foregroundStyle(Color.success)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.success.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        // Severe weather badge
                        if candidate.severeSegmentCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 7))
                                Text("\\(candidate.severeSegmentCount)")
                                    .font(.system(size: 8, weight: .medium))
                            }
                            .foregroundStyle(Color.danger)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.danger.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                // Score
                VStack(spacing: 1) {
                    Text("\\(candidate.score)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: candidate.scoreColorHex))
                        .monospacedDigit()
                    Text(candidate.scoreLabel)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Color(hex: candidate.scoreColorHex))
                }
                .frame(width: 40)

                // Checkmark for selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.liquidAccent)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.liquidAccent.opacity(0.08) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.liquidAccent.opacity(0.3) : Color.white.opacity(0.05), lineWidth: isSelected ? 1 : 0.5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(AppTheme.pressSpring, value: isPressed)
    }
}
