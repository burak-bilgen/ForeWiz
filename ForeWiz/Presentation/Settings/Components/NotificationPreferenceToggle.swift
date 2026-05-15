import SwiftUI

struct NotificationPreferenceToggle: View {
    @Binding var preference: NotificationPreference

    private var categoryIcon: String {
        switch preference.category {
        case .morningBriefing:   return "sunrise.fill"
        case .outfitSuggestion:  return "tshirt.fill"
        case .bestRunWindow:     return "figure.run"
        case .avoidHeatWindow:   return "thermometer.sun.fill"
        case .rainWarning:       return "cloud.rain.fill"
        case .windWarning:       return "wind"
        case .uvWarning:         return "sun.max.fill"
        }
    }

    var body: some View {
        LiquidGlassCard {
            HStack(spacing: 14) {
                GlassIcon(systemName: categoryIcon, color: .liquidAccent)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preference.category.localizedTitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(preference.category.localizedDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                Toggle("", isOn: $preference.isEnabled)
                    .tint(.liquidAccent)
                    .labelsHidden()
            }
            .padding(.vertical, 8)
        }
    }
}
