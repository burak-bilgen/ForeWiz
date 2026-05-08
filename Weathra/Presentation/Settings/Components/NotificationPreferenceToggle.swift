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

    private let accentColor = Color(red: 1.0, green: 0.45, blue: 0.45)

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(accentColor.opacity(0.16))
                    .frame(width: 34, height: 34)
                Image(systemName: categoryIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(preference.category.localizedTitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Text(preference.category.localizedDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.38))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: $preference.isEnabled)
                .tint(accentColor)
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}
