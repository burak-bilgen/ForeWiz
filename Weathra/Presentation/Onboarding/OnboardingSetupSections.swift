import SwiftUI
import UIKit

struct PermissionSetupSection: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                icon: "location.circle.fill",
                title: L10n.text("onboarding_permissions_title"),
                subtitle: L10n.text("onboarding_permissions_subtitle")
            )

            CompactPermissionRow(
                icon: "location.fill",
                title: L10n.text("onboarding_location_title"),
                message: L10n.text("onboarding_location_message"),
                statusText: statusText(for: viewModel.locationStatus),
                isRequired: true,
                actionTitle: locationActionTitle,
                action: requestOrOpenSettingsForLocation
            )

            CompactPermissionRow(
                icon: "bell.badge.fill",
                title: L10n.text("onboarding_notification_title"),
                message: L10n.text("onboarding_notification_message"),
                statusText: notificationText(for: viewModel.notificationStatus),
                isRequired: false,
                actionTitle: notificationActionTitle,
                action: requestOrOpenSettingsForNotifications
            )

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private var locationActionTitle: String {
        switch viewModel.locationStatus {
        case .authorized:
            L10n.text("permission_open")
        case .denied, .restricted:
            L10n.text("permission_settings")
        case .notDetermined:
            L10n.text("permission_allow")
        }
    }

    private var notificationActionTitle: String {
        switch viewModel.notificationStatus {
        case .authorized, .provisional:
            L10n.text("permission_open")
        case .denied:
            L10n.text("permission_settings")
        case .notDetermined:
            L10n.text("permission_allow")
        }
    }

    private func requestOrOpenSettingsForLocation() {
        if viewModel.locationStatus == .denied || viewModel.locationStatus == .restricted {
            openSettings()
        } else {
            viewModel.requestLocationPermission()
        }
    }

    private func requestOrOpenSettingsForNotifications() {
        if viewModel.notificationStatus == .denied {
            openSettings()
        } else {
            viewModel.requestNotificationPermission()
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        openURL(url)
    }

    private func statusText(for status: LocationAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            L10n.text("permission_pending")
        case .authorized:
            L10n.text("permission_open")
        case .denied, .restricted:
            L10n.text("permission_closed")
        }
    }

    private func notificationText(for status: NotificationAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            L10n.text("permission_optional")
        case .authorized:
            L10n.text("permission_open")
        case .provisional:
            L10n.text("permission_silent_on")
        case .denied:
            L10n.text("permission_closed")
        }
    }
}

// MARK: - Personalization Section

struct PersonalizationSection: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                icon: "slider.horizontal.3",
                title: L10n.text("onboarding_comfort_title"),
                subtitle: L10n.text("onboarding_comfort_subtitle")
            )

            Picker(L10n.text("onboarding_temp_sensitivity"), selection: Binding(
                get: { viewModel.selectedSensitivity },
                set: { viewModel.selectSensitivity($0) }
            )) {
                ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                    Text(sensitivity.localizedTitle).tag(sensitivity)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("onboarding_activities"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(ActivityType.allCases, id: \.self) { activity in
                        ActivityChip(
                            activity: activity,
                            isSelected: viewModel.preferredActivities.contains(activity)
                        ) {
                            viewModel.toggleActivity(activity)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}
