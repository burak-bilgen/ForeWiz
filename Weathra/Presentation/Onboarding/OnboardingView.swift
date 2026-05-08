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
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue.gradient)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 16) {
                    Text("Weathra")
                        .font(.system(size: 48, weight: .light))
                    Text("Sadece hava durumundan daha fazlası")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            VStack(spacing: 20) {
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

            Button(action: {
                HapticManager.medium()
                next()
            }) {
                Text("Devam Et")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
    }
}

private struct ModernFeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.blue.gradient)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.blue.opacity(0.02)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Modern Why Page

private struct ModernWhyPage: View {
    let next: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 20) {
                Text("Neden Weathra?")
                    .font(.system(size: 40, weight: .light))
                Text("Sana göre kararlar")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 20) {
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

            Button(action: {
                HapticManager.medium()
                next()
            }) {
                Text("Başlayalım")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
    }
}

private struct ModernComparisonCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(icon.contains("checkmark") ? Color.green.gradient : Color.red.gradient)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: icon.contains("checkmark")
                    ? [Color.green.opacity(0.08), Color.green.opacity(0.02)]
                    : [Color.red.opacity(0.08), Color.red.opacity(0.02)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((icon.contains("checkmark") ? Color.green : Color.red).opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Modern Setup Page

private struct ModernSetupPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let isCompleting: Bool
    let complete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Text("Kişiselleştir")
                    .font(.system(size: 40, weight: .light))
                Text("Senin için ayarlayalım")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 20) {
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

            Button(action: {
                HapticManager.medium()
                complete()
            }) {
                HStack {
                    if isCompleting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Hazırım")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(
                    LinearGradient(
                        colors: viewModel.canContinue ? [.blue, .blue.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
            .disabled(!viewModel.canContinue || isCompleting)
            .padding(.horizontal, 20)
        }
        .padding(24)
    }
}

private struct ModernSetupRow: View {
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.blue.gradient)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.blue.opacity(0.02)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.1), lineWidth: 1)
        )
    }
}
