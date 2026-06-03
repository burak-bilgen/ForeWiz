import SwiftUI
import WizPathKit

// MARK: - Journal List View

struct JournalListView: View {
    @State private var entries: [JournalEntry] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var selectedEntry: JournalEntry?
    @State private var showDetail = false

    private let journalStore: JournalStore

    init(journalStore: JournalStore) {
        self.journalStore = journalStore
    }

    var body: some View {
        ZStack {
            LiquidOrbBackground(palette: .default)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 48)

                if showSearch {
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Content
                if isLoading {
                    Spacer()
                    PulsingDotsLoader(color: .liquidAccent, dotSize: 8)
                    Spacer()
                } else if entries.isEmpty {
                    emptyState
                        .padding(.top, 40)
                } else {
                    entriesList
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .task { await loadEntries() }
        .sheet(isPresented: $showDetail) {
            if let entry = selectedEntry {
                JournalDetailView(
                    entry: entry,
                    journalStore: journalStore,
                    onDelete: { deletedId in
                        entries.removeAll { $0.id == deletedId }
                    }
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("journal_title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if !entries.isEmpty {
                    Text("\(entries.count) \(L10n.text("journal_entries_count"))")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            Button {
                HapticEngine.shared.light()
                withAnimation(AppTheme.cardSpring) {
                    showSearch.toggle()
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .environment(\.colorScheme, .dark)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))

            TextField(L10n.text("journal_search_placeholder"), text: $searchText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: searchText) { _, newValue in
                    Task { await searchEntries(query: newValue) }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    Task { await loadEntries() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .environment(\.colorScheme, .dark)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 80, height: 80)

                Image(systemName: "book.pages")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }

            Text(L10n.text("journal_no_entries"))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            Text(L10n.text("journal_empty_description"))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Entries List

    private var entriesList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(entries) { entry in
                    JournalEntryRow(entry: entry)
                        .onTapGesture {
                            HapticEngine.shared.light()
                            selectedEntry = entry
                            showDetail = true
                        }
                        .contextMenu {
                            Button {
                                selectedEntry = entry
                                showDetail = true
                            } label: {
                                Label(L10n.text("detail"), systemImage: "eye.fill")
                            }

                            Button(role: .destructive) {
                                Task { await deleteEntry(entry) }
                            } label: {
                                Label(L10n.text("action_delete"), systemImage: "trash.fill")
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .refreshable { await loadEntries() }
    }

    // MARK: - Actions

    private func loadEntries() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if searchText.isEmpty {
                entries = try await journalStore.fetchAll()
            } else {
                entries = try await journalStore.search(query: searchText)
            }
        } catch {
            entries = []
        }
    }

    private func searchEntries(query: String) async {
        guard !query.isEmpty else {
            await loadEntries()
            return
        }

        do {
            entries = try await journalStore.search(query: query)
        } catch {
            entries = []
        }
    }

    private func deleteEntry(_ entry: JournalEntry) async {
        do {
            try await journalStore.delete(entry)
            entries.removeAll { $0.id == entry.id }
            HapticEngine.shared.success()
        } catch {
            HapticEngine.shared.warning()
        }
    }
}

// MARK: - Journal Entry Row

struct JournalEntryRow: View {
    let entry: JournalEntry
    @State private var appears = false

    var body: some View {
        LiquidGlassCard(accentColor: accentColor, innerPadding: 14) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: entryIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(accentColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))

                        if let location = entry.locationName {
                            Text("•")
                                .foregroundStyle(.white.opacity(0.2))
                            Text(location)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Type badge
                Text(typeLabel)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(accentColor.opacity(0.25), lineWidth: 0.5))
            }
        }
        .opacity(appears ? 1 : 0)
        .offset(y: appears ? 0 : 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.05)) {
                appears = true
            }
        }
    }

    private var entryIcon: String {
        switch entry.typeRaw {
        case "trip": return "map.fill"
        case "commute": return "arrow.triangle.swap"
        case "explore": return "compass.drawing"
        default: return "mappin.and.ellipse"
        }
    }

    private var typeLabel: String {
        switch entry.typeRaw {
        case "trip": return L10n.text("journal_entry_trip")
        case "commute": return L10n.text("journal_entry_commute")
        case "explore": return L10n.text("journal_entry_explore")
        default: return entry.typeRaw
        }
    }

    private var accentColor: Color {
        switch entry.typeRaw {
        case "trip": return .liquidAccent
        case "commute": return .sunshine
        case "explore": return .success
        default: return .liquidAccent
        }
    }
}

// MARK: - Preview

#Preview {
    JournalListView(journalStore: MockJournalStore())
}
