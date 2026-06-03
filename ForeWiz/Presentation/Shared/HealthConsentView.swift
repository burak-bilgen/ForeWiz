import SwiftUI
import HealthKit
import WizPathKit

struct HealthDataType: Identifiable {
    let id: String
    let icon: String
    let titleKey: String
}

private let dataTypes: [HealthDataType] = [
    HealthDataType(id: "heartRate", icon: "heart.fill", titleKey: "health_heart_rate"),
    HealthDataType(id: "sleep", icon: "moon.zzz.fill", titleKey: "health_sleep"),
    HealthDataType(id: "steps", icon: "figure.walk", titleKey: "health_steps"),
    HealthDataType(id: "respiratory", icon: "lungs.fill", titleKey: "health_respiratory_rate"),
    HealthDataType(id: "uv", icon: "sun.max.fill", titleKey: "health_uv_exposure"),
]

struct HealthConsentView: View {
    @State private var viewModel: HealthConsentViewModel
    @Environment(\.dismiss) private var dismiss

    init(healthRepository: HealthRepository) {
        _viewModel = State(wrappedValue: HealthConsentViewModel(healthRepository: healthRepository))
    }

    var body: some View {
        ZStack {
            LiquidOrbBackground(palette: .default)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 16)
                scrollContent
                bottomBar
            }
        }
        .preferredColorScheme(.dark)
        .task { await viewModel.checkAuthorization() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppTheme.liquidAccent.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.liquidAccent)
            }
            .padding(.top, 24)

            Text(L10n.text("health_consent_title"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if viewModel.flowState != .healthKitUnavailable {
                Text(L10n.text("health_consent_message"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch viewModel.flowState {
                case .initial, .loading:
                    dataTypesList
                case .authorized:
                    authorizedView
                case .denied:
                    deniedView
                case .healthKitUnavailable:
                    unavailableView
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Data Types List

    private var dataTypesList: some View {
        LiquidGlassCard(accentColor: AppTheme.liquidAccent, innerPadding: 8) {
            VStack(spacing: 0) {
                ForEach(Array(dataTypes.enumerated()), id: \.element.id) { index, item in
                    DataTypeRow(item: item)
                    if index < dataTypes.count - 1 {
                        Divider()
                            .background(.white.opacity(0.06))
                            .padding(.leading, 52)
                    }
                }
            }
        }
    }

    // MARK: - Authorized View

    private var authorizedView: some View {
        LiquidGlassCard(accentColor: AppTheme.success, innerPadding: 16) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.success)

                Text(L10n.text("health_authorization_required"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                VStack(spacing: 0) {
                    ForEach(Array(dataTypes.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 15))
                                .foregroundStyle(AppTheme.success)
                                .frame(width: 28)
                            Text(L10n.text(item.titleKey))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.success)
                        }
                        .padding(.vertical, 10)
                        if index < dataTypes.count - 1 {
                            Divider().background(.white.opacity(0.06)).padding(.leading, 40)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Denied View

    private var deniedView: some View {
        LiquidGlassCard(accentColor: AppTheme.warning, innerPadding: 16) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.warning)

                Text(L10n.text("health_authorization_required"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(L10n.text("health_consent_message"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        LiquidGlassCard(accentColor: AppTheme.stormGray, innerPadding: 16) {
            VStack(spacing: 12) {
                Image(systemName: "xmark.icloud.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.stormGray)

                Text(L10n.text("health_service_unavailable"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            switch viewModel.flowState {
            case .initial:
                LiquidGlassButton(
                    L10n.text("health_consent_allow"),
                    icon: "heart.fill",
                    style: .primary,
                    haptic: .medium,
                    isFullWidth: true
                ) {
                    Task { await viewModel.requestAuthorization() }
                }

                LiquidGlassButton(
                    L10n.text("health_consent_deny"),
                    style: .tertiary,
                    isFullWidth: true
                ) {
                    dismiss()
                }

            case .loading:
                LiquidGlassButton(
                    L10n.text("health_consent_allow"),
                    icon: "heart.fill",
                    style: .primary,
                    haptic: .medium,
                    isFullWidth: true
                ) {}
                .disabled(true)
                .overlay(
                    ProgressView()
                        .tint(.white)
                )

            case .authorized, .healthKitUnavailable:
                LiquidGlassButton(
                    L10n.text("action_cancel"),
                    style: .tertiary,
                    isFullWidth: true
                ) {
                    dismiss()
                }

            case .denied:
                LiquidGlassButton(
                    L10n.text("action_open_settings"),
                    icon: "gearshape.fill",
                    style: .primary,
                    haptic: .medium,
                    isFullWidth: true
                ) {
                    viewModel.openSettings()
                }

                LiquidGlassButton(
                    L10n.text("action_cancel"),
                    style: .tertiary,
                    isFullWidth: true
                ) {
                    dismiss()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .padding(.top, 8)
    }
}

// MARK: - Data Type Row

private struct DataTypeRow: View {
    let item: HealthDataType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.liquidAccent)
                .frame(width: 28)

            Text(L10n.text(item.titleKey))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
}
