import SwiftUI

// MARK: - Feedback Dashboard View
/// Shows the user their submitted feedback history.
struct FeedbackDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = FeedbackDashboardStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if store.items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.items) { item in
                            FeedbackDashboardRow(item: item)
                                .onTapGesture {
                                    store.markRead(item.id)
                                }
                                .listRowBackground(Color.white.opacity(0.04))
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            withAnimation {
                                store.removeItems(at: indexSet)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(L10n.text("feedback_dashboard_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !store.items.isEmpty {
                        Button(L10n.text("feedback_dashboard_clear")) {
                            withAnimation {
                                store.removeAll()
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { HapticEngine.shared.light(); dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 44))
                .foregroundStyle(.linearGradient(
                    colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9F0A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text(L10n.text("feedback_dashboard_empty"))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text(L10n.text("feedback_dashboard_empty_desc"))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Dashboard Row

private struct FeedbackDashboardRow: View {
    let item: FeedbackDashboardItem

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: typeIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(typeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    if !item.isRead {
                        Circle()
                            .fill(Color(hex: "#FFD60A"))
                            .frame(width: 6, height: 6)
                    }

                    if !item.success {
                        Text("(" + L10n.text("feedback_dashboard_failed") + ")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "#FF453A"))
                    }
                }

                Text(item.message)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(formattedDate)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(item.success ? Color(hex: "#30D158") : Color(hex: "#FF453A").opacity(0.5))
                .opacity(item.isRead ? 0.5 : 1)
        }
        .padding(.vertical, 4)
    }

    private var typeColor: Color {
        switch item.type {
        case "bugReport": return Color(hex: "#FF453A")
        case "featureRequest": return Color(hex: "#FFD60A")
        default: return Color(hex: "#30D158")
        }
    }

    private var typeIcon: String {
        switch item.type {
        case "bugReport": return "ant.fill"
        case "featureRequest": return "sparkles"
        default: return "bubble.left.and.bubble.right.fill"
        }
    }

    private var formattedDate: String {
        item.submittedAt.formatted(date: .abbreviated, time: .shortened)
    }
}

// MARK: - Preview

#Preview {
    FeedbackDashboardView()
}
