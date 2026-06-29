import SwiftUI
import PhotosUI

struct FeedbackSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var feedbackType: FeedbackService.FeedbackType = .generalFeedback
    @State private var title: String = ""
    @State private var message: String = ""
    @State private var email: String = ""
    @State private var isSubmitting = false
    @State private var submitSuccess = false
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var showDashboard = false
    @State private var dashboardStore = FeedbackDashboardStore.shared

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty &&
        (email.isEmpty || isValidEmail(email))
    }

    private var isEmailInvalid: Bool {
        !email.isEmpty && !isValidEmail(email)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    VStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.linearGradient(
                                colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9F0A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .padding(.bottom, 4)

                        Text(L10n.text("feedback_sheet_title"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(L10n.text("feedback_sheet_subtitle"))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 8) {
                        Text(L10n.text("feedback_type_label"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 8) {
                            ForEach(FeedbackService.FeedbackType.allCases, id: \.self) { type in
                                feedbackTypeButton(type)
                            }
                        }
                    }

                    VStack(spacing: 6) {
                        Text(L10n.text("feedback_title_label"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField(L10n.text("feedback_title_placeholder"), text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
                            )
                    }

                    VStack(spacing: 6) {
                        Text(L10n.text("feedback_message_label"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextEditor(text: $message)
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(minHeight: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
                            )
                            .overlay(alignment: .topLeading) {
                                if message.isEmpty {
                                    Text(L10n.text("feedback_message_placeholder"))
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white.opacity(0.3))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    VStack(spacing: 6) {
                        Text(L10n.text("feedback_email_label"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField(L10n.text("feedback_email_placeholder"), text: $email)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
                            )

                        if isEmailInvalid {
                            Text(L10n.text("feedback_email_invalid"))
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "#FF453A"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(L10n.text("feedback_email_hint"))
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.35))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    VStack(spacing: 6) {
                        Text(L10n.text("feedback_screenshot_label"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                HStack(spacing: 6) {
                                    Image(systemName: selectedPhotoData != nil ? "photo.fill" : "camera.badge.ellipsis")
                                        .font(.system(size: 14))
                                    Text(selectedPhotoData != nil ? L10n.text("feedback_screenshot_added") : L10n.text("feedback_screenshot_add"))
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(selectedPhotoData != nil ? Color(hex: "#30D158") : .white.opacity(0.6))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPhotoData != nil ? Color(hex: "#30D158").opacity(0.1) : .white.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPhotoData != nil ? Color(hex: "#30D158").opacity(0.3) : .white.opacity(0.08), lineWidth: 0.5)
                                )
                            }

                            if selectedPhotoData != nil {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedPhotoItem = nil
                                        selectedPhotoData = nil
                                        HapticEngine.shared.light()
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                        }

                        Text(L10n.text("feedback_screenshot_hint"))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.35))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            guard let item = newItem else { return }
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedPhotoData = data
                                    }
                                    HapticEngine.shared.selectionChanged()
                                }
                            }
                        }
                    }

                    Button {
                        submitFeedback()
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14))
                            }
                            Text(isSubmitting
                                 ? L10n.text("feedback_sending")
                                 : L10n.text("feedback_send"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isFormValid
                                      ? Color(hex: "#FFD60A")
                                      : Color.white.opacity(0.1))
                        )
                        .foregroundStyle(isFormValid ? .black : .white.opacity(0.3))
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticEngine.shared.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .sheet(isPresented: $showDashboard) {
                FeedbackDashboardView()
            }
            .overlay {
                if submitSuccess {
                    successOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }
            }
        }
    }

    private func feedbackTypeButton(_ type: FeedbackService.FeedbackType) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                feedbackType = type
                HapticEngine.shared.selectionChanged()
            }
        } label: {
            Text(type.displayTitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(feedbackType == type
                              ? Color(hex: "#FFD60A").opacity(0.2)
                              : .white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(feedbackType == type
                                ? Color(hex: "#FFD60A").opacity(0.4)
                                : .white.opacity(0.06),
                                lineWidth: 0.5)
                )
                .foregroundStyle(feedbackType == type
                                 ? Color(hex: "#FFD60A")
                                 : .white.opacity(0.6))
        }
    }

    private func submitFeedback() {
        guard isFormValid else { return }
        isSubmitting = true
        errorMessage = nil
        HapticEngine.shared.medium()

        Task {
            do {
                try await FeedbackService.sendFeedback(
                    type: feedbackType,
                    title: title,
                    message: message,
                    email: email,
                    screenshotData: selectedPhotoData
                )

                await MainActor.run {
                    isSubmitting = false
                    submitSuccess = true
                    HapticEngine.shared.success()
                    dashboardStore.addItem(
                        type: feedbackType.rawValue,
                        title: title,
                        message: message,
                        success: true
                    )
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    HapticEngine.shared.error()
                    dashboardStore.addItem(
                        type: feedbackType.rawValue,
                        title: title,
                        message: message,
                        success: false
                    )
                }
            }
        }
    }

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "#30D158"))

            Text(L10n.text("feedback_thanks"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(L10n.text("feedback_success_detail"))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                HapticEngine.shared.light()
                showDashboard = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 13))
                    Text(L10n.text("feedback_dashboard_view"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color(hex: "#FFD60A"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#FFD60A").opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#FFD60A").opacity(0.25), lineWidth: 0.5)
                )
            }
            .padding(.top, 4)

            Button {
                HapticEngine.shared.light()
                dismiss()
            } label: {
                Text(L10n.text("feedback_dismiss"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .underline()
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    FeedbackSheetView()
}
