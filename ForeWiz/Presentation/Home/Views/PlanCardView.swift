import SwiftUI

/// Daily plan card showing actionable weather insights.
struct PlanCardView: View {
    let plan: HomePlanViewState
    
    var body: some View {
        GlassCard(accentColor: Color(red: 0.35, green: 0.82, blue: 0.66)) {
            VStack(alignment: .leading, spacing: 12) {
                header
                planItemsList
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
    
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.5))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
                
                Text(plan.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
    }
    
    private var planItemsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(plan.items.enumerated()), id: \.element.id) { index, item in
                PlanItemRow(item: item)
                
                if index < plan.items.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.05))
                        .padding(.leading, 36)
                }
            }
        }
    }
}

// MARK: - Plan Item Row

struct PlanItemRow: View {
    let item: HomePlanItem
    
    private var toneColor: Color { AppTheme.toneColor(for: item.tone) }
    
    var body: some View {
        HStack(spacing: 10) {
            iconContainer
            content
            Spacer(minLength: 6)
            timeBadge
        }
        // Apple HIG: 44pt minimum touch target
        .frame(minHeight: 44)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var iconContainer: some View {
        ZStack {
            Circle()
                .fill(toneColor.opacity(item.isPrimary ? 0.18 : 0.08))
                .frame(width: 32, height: 32)
            
            Image(systemName: item.icon)
                .font(.system(size: 13, weight: item.isPrimary ? .semibold : .medium))
                .foregroundStyle(toneColor)
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
                .font(.system(size: 13, weight: item.isPrimary ? .bold : .semibold))
                .foregroundStyle(item.isPrimary ? .white : Color.white.opacity(0.85))
            
            Text(item.detail)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var timeBadge: some View {
        Text(item.timeText)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(toneColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(toneColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        PlanCardView(plan: HomePlanViewState(
            title: "Today's Plan",
            subtitle: "A short action plan built for you",
            items: [
                HomePlanItem(
                    id: "now",
                    icon: "checkmark.seal.fill",
                    title: "Now",
                    timeText: "Good to go",
                    detail: "Outdoor score: 85",
                    tone: .good,
                    isPrimary: true
                ),
                HomePlanItem(
                    id: "best-window",
                    icon: "clock.fill",
                    title: "Outdoor Plan",
                    timeText: "14:00 - 16:00",
                    detail: "Best window for activities",
                    tone: .good,
                    isPrimary: false
                ),
                HomePlanItem(
                    id: "outfit",
                    icon: "tshirt.fill",
                    title: "Prep",
                    timeText: "Light layers",
                    detail: "T-shirt, light jacket",
                    tone: .info,
                    isPrimary: false
                )
            ]
        ))
        .padding()
    }
}
