import SwiftUI

struct ActivityPickerView: View {
    @Binding var selectedActivity: ActivityType?
    @Namespace private var selectionNamespace

    private let activities = ActivityType.allCases

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    allActivitiesPill

                    ForEach(activities, id: \.self) { activity in
                        activityPill(activity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    private var allActivitiesPill: some View {
        Button {
            HapticEngine.shared.medium()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedActivity = nil
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                Text(L10n.text("activity_picker_all"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                selectedActivity == nil
                    ? AppTheme.liquidAccent.opacity(0.2)
                    : .white.opacity(0.05),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(
                        selectedActivity == nil
                            ? AppTheme.liquidAccent.opacity(0.4)
                            : .white.opacity(0.06),
                        lineWidth: 0.8
                    )
            )
            .foregroundStyle(selectedActivity == nil ? AppTheme.liquidAccent : .white.opacity(0.6))
        }
        .buttonStyle(.fullTapArea)
        .accessibilityLabel(L10n.text("activity_all"))
        .accessibilityAddTraits(selectedActivity == nil ? .isSelected : [])
        .matchedGeometryEffect(id: "pill-all", in: selectionNamespace)
    }

    private func activityPill(_ activity: ActivityType) -> some View {
        let isSelected = selectedActivity == activity

        return Button {
            HapticEngine.shared.medium()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedActivity = activity
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: activity.iconName)
                    .font(.system(size: 13, weight: .semibold))
                Text(L10n.text(activity.localizedTitle))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected
                    ? AppTheme.liquidAccent.opacity(0.2)
                    : .white.opacity(0.05),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected
                            ? AppTheme.liquidAccent.opacity(0.4)
                            : .white.opacity(0.06),
                        lineWidth: 0.8
                    )
            )
            .foregroundStyle(isSelected ? AppTheme.liquidAccent : .white.opacity(0.6))
        }
        .buttonStyle(.fullTapArea)
        .accessibilityLabel(L10n.text(activity.localizedTitle))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        AppTheme.ambientGradient(for: .dark)
            .ignoresSafeArea()

        ActivityPickerView(selectedActivity: .constant(nil))
    }
}
