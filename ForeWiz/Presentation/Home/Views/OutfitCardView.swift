import SwiftUI

/// Outfit recommendation card with clothing and accessory suggestions.
struct OutfitCardView: View {
    let outfit: OutfitRecommendation
    
    var body: some View {
        GlassCard(accentColor: Color(red: 1.0, green: 0.68, blue: 0.32)) {
            VStack(alignment: .leading, spacing: 14) {
                header
                outfitDetails
                accessoriesSection
            }
            .padding(14)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L10n.text("home_outfit_card_title")): \(outfit.title)")
    }
    
    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            iconContainer
            titleSection
        }
    }
    
    private var iconContainer: some View {
        ZStack {
            Circle()
                .fill(Color(red: 1.0, green: 0.68, blue: 0.32).opacity(0.16))
                .frame(width: 36, height: 36)
            
            Image(systemName: "tshirt.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.35))
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(L10n.text("home_outfit_card_title"))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            
            Text(L10n.text("home_outfit_card_subtitle"))
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.48))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var outfitDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(outfit.title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            if !outfit.items.isEmpty {
                itemsList
            }
        }
    }
    
    private var itemsList: some View {
        Text(L10n.formatted("home_outfit_items_intro", outfit.items.prefix(4).joined(separator: ", ")))
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.72))
            .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    private var accessoriesSection: some View {
        if !outfit.accessories.isEmpty || outfit.warning != nil {
            VStack(alignment: .leading, spacing: 10) {
                if !outfit.accessories.isEmpty {
                    accessoriesList
                }
                
                if let warning = outfit.warning {
                    warningView(warning)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.62))
            .labelStyle(.titleAndIcon)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var accessoriesList: some View {
        Label(
            L10n.formatted("home_outfit_accessories", outfit.accessories.prefix(3).joined(separator: ", ")),
            systemImage: "sparkles"
        )
    }
    
    private func warningView(_ warning: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.3))
            
            Text(warning)
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 16) {
            // Full outfit
            OutfitCardView(outfit: OutfitRecommendation(
                title: "Light layers",
                items: ["T-shirt", "Light jacket", "Jeans"],
                accessories: ["Sunglasses", "Sunscreen"],
                warning: "UV index is high today"
            ))
            
            // Minimal outfit
            OutfitCardView(outfit: OutfitRecommendation(
                title: "Warm layers",
                items: ["Coat", "Sweater", "Boots"],
                accessories: [],
                warning: nil
            ))
        }
        .padding()
    }
}
