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
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("HavaAsistani")
                                .font(AppTypography.largeTitle)
                            Text(
                                "Hava durumunu yorumlamak yerine bugün ne yapman gerektiğini söyleyen kişisel asistan."
                            )
                                .font(AppTypography.body)
                                .foregroundStyle(.secondary)
                        }

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
                                Picker("Sıcaklık hassasiyeti", selection: Binding(
                                    get: { viewModel.selectedSensitivity },
                                    set: viewModel.selectSensitivity
                                )) {
                                    ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                                        Text(sensitivity.localizedTitle).tag(sensitivity)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        PrimaryButton(title: "Devam et", systemImage: "arrow.right", action: onCompleted)
                    }
                    .padding(AppSpacing.large)
                }
            }
        }
    }
}
