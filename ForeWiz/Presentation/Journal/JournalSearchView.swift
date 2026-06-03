import SwiftUI

// MARK: - Journal Search View

struct JournalSearchView: View {
    @Binding var searchText: String
    let results: [JournalEntry]
    let onSelect: (JournalEntry) -> Void
    let onClear: () -> Void

    @State private var selectedFilter: FilterType = .all
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var showDateFilter = false

    private enum FilterType: String, CaseIterable {
        case all; case trips; case commutes; case explores

        var rawValues: [String] {
            switch self {
            case .all: return ["trip", "commute", "explore"]
            case .trips: return ["trip"]; case .commutes: return ["commute"]; case .explores: return ["explore"]
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterChips
            if showDateFilter { dateFilterView.transition(.opacity.combined(with: .move(edge: .top))) }
            if results.isEmpty { emptyResults.padding(.top, 40) } else { resultsList }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.4))
            TextField(L10n.text("journal_search_placeholder"), text: $searchText)
                .font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white)
                .autocorrectionDisabled().textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button(action: onClear) { Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundStyle(.white.opacity(0.4)) }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .environment(\.colorScheme, .dark)
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.06), lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterType.allCases, id: \.self) { filter in chip(filter) }
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { showDateFilter.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.system(size: 11))
                        Text(L10n.text("date_filter")).font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(showDateFilter ? AppTheme.liquidAccent : .white.opacity(0.5))
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(showDateFilter ? AppTheme.liquidAccent.opacity(0.1) : .white.opacity(0.04), in: Capsule())
                    .overlay(Capsule().stroke(showDateFilter ? AppTheme.liquidAccent.opacity(0.3) : .white.opacity(0.06), lineWidth: 0.5))
                }.buttonStyle(.plain)
            }.padding(.horizontal, 20).padding(.vertical, 10)
        }
    }

    private func chip(_ filter: FilterType) -> some View {
        let isSelected = selectedFilter == filter
        return Button {
            HapticEngine.shared.selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedFilter = filter }
        } label: {
            Text(filterLabel(filter)).font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? AppTheme.liquidAccent : .white.opacity(0.5))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(isSelected ? AppTheme.liquidAccent.opacity(0.1) : .white.opacity(0.04), in: Capsule())
                .overlay(Capsule().stroke(isSelected ? AppTheme.liquidAccent.opacity(0.3) : .white.opacity(0.06), lineWidth: 0.5))
        }.buttonStyle(.plain)
    }

    private func filterLabel(_ filter: FilterType) -> String {
        switch filter {
        case .all: return L10n.text("all")
        case .trips: return L10n.text("journal_entry_trip") + "s"
        case .commutes: return L10n.text("journal_entry_commute") + "s"
        case .explores: return L10n.text("journal_entry_explore") + "s"
        }
    }

    // MARK: - Date Filter
    private var dateFilterView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("date_filter_from")).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
                    DatePicker("", selection: $startDate, displayedComponents: .date).datePickerStyle(.compact).labelsHidden().tint(AppTheme.liquidAccent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("date_filter_to")).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
                    DatePicker("", selection: $endDate, displayedComponents: .date).datePickerStyle(.compact).labelsHidden().tint(AppTheme.liquidAccent)
                }
            }
        }
        .padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .environment(\.colorScheme, .dark)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.06), lineWidth: 1))
        .padding(.horizontal, 20).padding(.bottom, 8)
    }

    // MARK: - Empty / Results
    private var emptyResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.system(size: 32)).foregroundStyle(.white.opacity(0.2))
            Text(L10n.text("journal_no_results")).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
        }
    }

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(filteredResults) { entry in
                    JournalEntryRow(entry: entry).onTapGesture { HapticEngine.shared.light(); onSelect(entry) }
                }
            }.padding(.horizontal, 20).padding(.vertical, 12)
        }
    }

    private var filteredResults: [JournalEntry] {
        let filtered = selectedFilter == .all ? results : results.filter { selectedFilter.rawValues.contains($0.typeRaw) }
        guard showDateFilter else { return filtered }
        return filtered.filter { $0.date >= startDate && $0.date <= endDate }
    }
}
