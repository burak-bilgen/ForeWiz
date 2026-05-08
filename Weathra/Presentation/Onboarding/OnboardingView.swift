import SwiftUI

/// Three-step onboarding: hero, comparison, setup.
struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                ModernHeroPage(next: { goTo(1) })
                    .tag(0)
                ModernWhyPage(next: { goTo(2) })
                    .tag(1)
                ModernSetupPage(
                    viewModel: viewModel,
                    isCompleting: isCompleting,
                    complete: complete
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func goTo(_ page: Int) {
        withAnimation(.easeInOut) {
            currentPage = page
        }
    }

    private func complete() {
        guard viewModel.canContinue, !isCompleting else { return }
        isCompleting = true
        Task {
            do {
                try await onCompleted(viewModel.makeProfile(inheriting: existingProfile))
            } catch {
                viewModel.setErrorMessage(AppError.persistenceFailed.userMessage)
            }
            isCompleting = false
        }
    }
}

// MARK: - Modern Hero Page

private struct ModernHeroPage: View {
    let next: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                VStack(spacing: 12) {
                    Text("Weathra")
                        .font(.system(size: 42, weight: .bold))
                    Text("Sadece hava durumundan daha fazlası")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                ModernFeatureCard(
                    icon: "lightbulb.fill",
                    title: "Akıllı Kararlar",
                    description: "Hava durumuna göre ne yapman gerektiğini söyler"
                )
                ModernFeatureCard(
                    icon: "calendar.fill",
                    title: "En İyi Zamanlar",
                    description: "Aktivitelerin için en uygun saatleri bulur"
                )
                ModernFeatureCard(
                    icon: "tshirt.fill",
                    title: "Kıyafet Önerileri",
                    description: "Güne göre ne giymen gerektiğini önerir"
                )
            }

            Button(action: next) {
                Text("Devam Et")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
        }
        .padding(20)
    }
}

private struct ModernFeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

// MARK: - Modern Why Page

private struct ModernWhyPage: View {
    let next: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("Neden Weathra?")
                    .font(.system(size: 36, weight: .bold))
                Text("Sana göre kararlar")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                ModernComparisonCard(
                    icon: "xmark.circle.fill",
                    title: "Diğer Hava Uygulamaları",
                    description: "Sadece sıcaklık ve nem verir"
                )
                ModernComparisonCard(
                    icon: "checkmark.circle.fill",
                    title: "Weathra",
                    description: "Ne yapman gerektiğini söyler"
                )
            }

            Button(action: next) {
                Text("Başlayalım")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
        }
        .padding(20)
    }
}

private struct ModernComparisonCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(icon.contains("checkmark") ? .green : .red)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

// MARK: - Modern Setup Page

private struct ModernSetupPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let isCompleting: Bool
    let complete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("Kişiselleştir")
                    .font(.system(size: 36, weight: .bold))
                Text("Senin için ayarlayalım")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                ModernSetupRow(
                    title: "Konum İzni",
                    description: "Bulunduğun yere ait hava durumu için gerekli",
                    icon: "location.fill"
                )

                ModernSetupRow(
                    title: "Bildirimler",
                    description: "Uygun saatleri sana hatırlatabilmemiz için",
                    icon: "bell.fill"
                )

                ModernSetupRow(
                    title: "Hassasiyet",
                    description: "Sıcaklığa karşı toleransını seç",
                    icon: "thermometer"
                )
            }

            Button(action: complete) {
                HStack {
                    if isCompleting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Hazırım")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(viewModel.canContinue ? .blue : .gray, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canContinue || isCompleting)
            .padding(.horizontal, 20)
        }
        .padding(20)
    }
}

private struct ModernSetupRow: View {
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}
