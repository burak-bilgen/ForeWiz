import SwiftUI

// MARK: - EV Range Planner Panel
public struct EvRangePlannerPanel: View {
    let rangeEstimate: EvRangeEstimate?
    let chargingPlan: EvChargingPlan?
    let evRecommendations: [EVRecommendation]
    
    @State private var isBreathing = false

    public init(
        rangeEstimate: EvRangeEstimate?,
        chargingPlan: EvChargingPlan?,
        evRecommendations: [EVRecommendation]
    ) {
        self.rangeEstimate = rangeEstimate
        self.chargingPlan = chargingPlan
        self.evRecommendations = evRecommendations
    }

    public var body: some View {
        LiquidGlassCard(accentColor: Color(hex: "#00D9FF"), innerPadding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "bolt.car.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#00D9FF"))
                    Text(WizPathKitL10n.text("ev_range_title"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "battery.100.bolt")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#00D9FF"))
                }

                if let rangeEstimate {
                    // Metrics Row
                    HStack(spacing: 12) {
                        // Weather-Adjusted Range Metric
                        VStack(alignment: .leading, spacing: 4) {
                            Text(WizPathKitL10n.text("ev_adjusted_range_title"))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            let adjustedStr = String(format: "%.0f km", rangeEstimate.adjustedRangeKm)
                            let baseStr = String(format: "%.0f km", rangeEstimate.baseRangeKm)
                            Text(WizPathKitL10n.formatted("ev_adjusted_range_value", adjustedStr, baseStr))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                            .frame(height: 32)
                            .background(Color.white.opacity(0.1))

                        // Average Consumption Metric
                        VStack(alignment: .leading, spacing: 4) {
                            Text(WizPathKitL10n.text("ev_avg_consumption_title"))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            Text(WizPathKitL10n.formatted("ev_avg_consumption_value", rangeEstimate.consumptionWhPerKm))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)

                    // Destination Battery Level
                    let destCharge = destinationCharge
                    HStack(spacing: 8) {
                        Image(systemName: destCharge < 15.0 ? "battery.25" : "battery.75")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(destCharge < 15.0 ? Color(hex: "#FF453A") : Color(hex: "#30D158"))
                        
                        Text(WizPathKitL10n.text("ev_dest_charge_title"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                        
                        Spacer()
                        
                        Text(WizPathKitL10n.formatted("ev_dest_charge_value", Int(destCharge)))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(destCharge < 15.0 ? Color(hex: "#FF453A") : Color(hex: "#30D158"))
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                destCharge < 15.0
                                    ? Color(hex: "#FF453A").opacity(isBreathing ? 0.45 : 0.15)
                                    : Color.clear,
                                lineWidth: 1.0
                            )
                    )
                    .shadow(
                        color: destCharge < 15.0
                            ? Color(hex: "#FF453A").opacity(isBreathing ? 0.35 : 0.1)
                            : Color.clear,
                        radius: isBreathing ? 10 : 4
                    )
                    .scaleEffect(destCharge < 15.0 ? (isBreathing ? 1.015 : 0.99) : 1.0)

                    // Smart Scheduled Stops Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(WizPathKitL10n.text("ev_charging_stops_title"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, 4)

                        if let chargingPlan, !chargingPlan.stops.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(chargingPlan.stops.enumerated()), id: \.element.chargerStop.id) { index, stop in
                                    HStack(alignment: .top, spacing: 10) {
                                        // Vertical Bullet Line Node
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(Color(hex: "#00D9FF"))
                                                .frame(width: 8, height: 8)
                                                .shadow(color: Color(hex: "#00D9FF").opacity(0.5), radius: 4)
                                                .padding(.top, 4)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(stop.chargerStop.name)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(.white)
                                            
                                            let costStr = String(format: "$%.2f", stop.estimatedCost)
                                            Text(WizPathKitL10n.formatted("ev_charging_stop_item", stop.recommendation, costStr))
                                                .font(.system(size: 11))
                                                .foregroundStyle(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                }
                            }
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: chargingPlan.stops)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "#30D158"))
                                
                                Text(WizPathKitL10n.text("ev_no_stops_needed"))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } else {
                    // Shimmer or Placeholder during calculation
                    ShimmerSkeletonView()
                }

                // Consolidated Temperature/AC Recommendations
                if !evRecommendations.isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(evRecommendations) { rec in
                            HStack(spacing: 8) {
                                Image(systemName: rec.icon)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#00D9FF"))
                                    .frame(width: 16)
                                
                                Text(rec.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Spacer()
                                
                                Text(rec.description)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }

    private var destinationCharge: Double {
        if let plan = chargingPlan {
            return plan.destinationChargePercent
        }
        guard let estimate = rangeEstimate else { return 80.0 }
        let totalUsedKwh = estimate.segments.map(\.energyUsedKwh).reduce(0.0, +)
        let usedPercent = (totalUsedKwh / 75.0) * 100.0
        return max(0.0, 80.0 - usedPercent)
    }
}

// MARK: - Shimmer Skeleton View
struct ShimmerSkeletonView: View {
    @State private var phase: CGFloat = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
                .frame(width: 140, height: 14)
                .overlay(shimmerOverlay())
            
            // Metrics skeletons
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 80, height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 110, height: 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 80, height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 110, height: 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            
            // Battery safety bar skeleton
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
                .frame(height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
                .overlay(shimmerOverlay())
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }

    @ViewBuilder
    private func shimmerOverlay() -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            LinearGradient(
                colors: [.clear, .white.opacity(0.12), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: width * 1.5, height: height)
            .offset(x: -width + (phase * width * 2))
        }
        .mask(RoundedRectangle(cornerRadius: 4))
    }
}
