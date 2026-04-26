import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let onCompleted: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            Text("WeatherAssistant")
                                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)

                            Text(
                                "Hava durumunu yorumlamak yerine bugün ne yapman gerektiğini söyleyen kişisel asistan."
                            )
                                .font(AppTypography.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, AppSpacing.medium)

                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                                PermissionExplainerView(
                                    systemImage: "location.fill",
                                    title: "Konum",
                                    message: "Konumunu sadece bulunduğun yere uygun hava önerileri üretmek " +
                                        "için kullanıyoruz."
                                )
                                PermissionExplainerView(
                                    systemImage: "bell.badge.fill",
                                    title: "Akıllı bildirimler",
                                    message: "Sadece anlamlı hava pencereleri için kısa ve seyrek uyarılar göndeririz."
                                )
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                                Text("Sıcaklık hassasiyeti")
                                    .font(AppTypography.headline)

                                VStack(spacing: AppSpacing.small) {
                                    ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                                        SensitivityRow(
                                            sensitivity: sensitivity,
                                            isSelected: viewModel.selectedSensitivity == sensitivity
                                        ) {
                                            viewModel.selectSensitivity(sensitivity)
                                        }
                                    }
                                }
                            }
                        }

                        PrimaryButton(title: "Devam et", systemImage: "arrow.right", action: onCompleted)
                    }
                    .padding(AppSpacing.large)
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct SensitivityRow: View {
    let sensitivity: TemperatureSensitivity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: iconName)
                    .font(.headline)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.14), in: Circle())
                    .foregroundStyle(tint)

                Text(sensitivity.localizedTitle)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.success : .secondary)
            }
            .padding(AppSpacing.medium)
            .background(.white.opacity(isSelected ? 0.58 : 0.30), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var iconName: String {
        switch sensitivity {
        case .getsColdEasily:
            "snowflake"
        case .normal:
            "thermometer.medium"
        case .getsHotEasily:
            "sun.max.fill"
        }
    }

    private var tint: Color {
        switch sensitivity {
        case .getsColdEasily:
            AppTheme.accent
        case .normal:
            AppTheme.teal
        case .getsHotEasily:
            AppTheme.warning
        }
    }
}
