import SwiftUI
import CoreLocation
import WizPathKit

// MARK: - Journal Detail View

struct JournalDetailView: View {
    let entry: JournalEntry
    let journalStore: JournalStore
    let onDelete: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var notes: String = ""
    @State private var hasUnsavedNotes = false
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var isGeneratingShare = false

    private var routeSnapshot: RouteSnapshot? {
        guard let data = entry.routeData else { return nil }
        return try? JSONDecoder().decode(RouteSnapshot.self, from: data)
    }

    var body: some View {
        ZStack {
            LiquidOrbBackground(palette: .default).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection.padding(.top, 16)
                    if let route = routeSnapshot { routeSummaryCard(route: route) }
                    dateLocationCard
                    if entry.weatherSnapshotData != nil { weatherInfoCard }
                    if entry.healthData != nil { healthInfoCard }
                    notesSection
                    actionButtons.padding(.bottom, 32)
                }.padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark).navigationBarHidden(true)
        .onAppear { notes = entry.notes ?? "" }
        .alert(L10n.text("journal_delete"), isPresented: $showDeleteConfirmation) {
            Button(L10n.text("action_delete"), role: .destructive) { Task { await deleteEntry() } }
            Button(L10n.text("action_cancel"), role: .cancel) {}
        } message: { Text(L10n.text("journal_delete_confirmation")) }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage { ShareSheet(activityItems: [image]) }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Button {
                if hasUnsavedNotes { Task { await saveNotes() } }
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                    Text(L10n.text("back")).font(.system(size: 15, weight: .medium, design: .rounded))
                }.foregroundStyle(.white.opacity(0.6))
            }.buttonStyle(.plain)
            Spacer()
            Text(L10n.text("journal_detail")).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Button { Task { await generateAndShareImage() } } label: {
                Image(systemName: "square.and.arrow.up").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white.opacity(0.6))
            }.buttonStyle(.plain).disabled(isGeneratingShare)
        }
    }

    // MARK: - Route Summary Card
    private func routeSummaryCard(route: RouteSnapshot) -> some View {
        LiquidGlassCard(accentColor: AppTheme.liquidAccent, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    GlassIcon(systemName: travelModeIcon(route.travelModeRaw), color: AppTheme.liquidAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(route.originName).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                        Image(systemName: "arrow.down").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.3))
                        Text(route.destinationName).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white).lineLimit(1)
                    }
                }
                Divider().background(.white.opacity(0.06))
                HStack(spacing: 0) {
                    statItem(label: L10n.text("duration"), value: formattedDuration(route.totalDuration))
                    Divider().background(.white.opacity(0.06)).frame(height: 32)
                    statItem(label: L10n.text("distance"), value: formattedDistance(route.totalDistance))
                    Divider().background(.white.opacity(0.06)).frame(height: 32)
                    statItem(label: L10n.text("safety"), value: "\(route.safetyScore)")
                }
                if route.hazardCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 11)).foregroundStyle(AppTheme.warning)
                        Text(L10n.formatted("journal_hazards_count", route.hazardCount))
                            .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(AppTheme.warning.opacity(0.8))
                    }
                }
            }
        }
    }

    // MARK: - Date & Location Card
    private var dateLocationCard: some View {
        LiquidGlassCard(accentColor: .white, innerPadding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.06)).frame(width: 40, height: 40)
                    Image(systemName: "calendar").font(.system(size: 16, weight: .medium)).foregroundStyle(.white.opacity(0.5))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date.formatted(date: .long, time: .shortened)).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                    if let loc = entry.locationName {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill").font(.system(size: 10)).foregroundStyle(.white.opacity(0.3))
                            Text(loc).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                Spacer()
                Text(typeBadge).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(typeColor)
                    .padding(.horizontal, 8).padding(.vertical, 4).background(typeColor.opacity(0.12), in: Capsule())
                    .overlay(Capsule().stroke(typeColor.opacity(0.25), lineWidth: 0.5))
            }
        }
    }

    // MARK: - Weather & Health Info Cards
    private var weatherInfoCard: some View {
        LiquidGlassCard(accentColor: AppTheme.sunshine, innerPadding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.sunshine.opacity(0.12)).frame(width: 40, height: 40)
                    Image(systemName: "cloud.sun.fill").font(.system(size: 16, weight: .medium)).foregroundStyle(AppTheme.sunshine)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("weather")).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.5))
                    Text(L10n.text("journal_weather_recorded")).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.2))
            }
        }
    }

    private var healthInfoCard: some View {
        LiquidGlassCard(accentColor: AppTheme.success, innerPadding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(AppTheme.success.opacity(0.12)).frame(width: 40, height: 40)
                    Image(systemName: "heart.text.square.fill").font(.system(size: 16, weight: .medium)).foregroundStyle(AppTheme.success)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("health")).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.5))
                    Text(L10n.text("journal_health_recorded")).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.2))
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        LiquidGlassCard(accentColor: .white, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "note.text").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white.opacity(0.45))
                    Text(L10n.text("journal_notes_placeholder")).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.45))
                    Spacer()
                    if hasUnsavedNotes {
                        Button(L10n.text("action_save")) { Task { await saveNotes() } }
                            .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.liquidAccent).buttonStyle(.plain)
                    }
                }
                TextEditor(text: $notes).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                    .scrollContentBackground(.hidden).background(.clear).frame(minHeight: 80)
                    .onChange(of: notes) { _, _ in hasUnsavedNotes = notes != (entry.notes ?? "") }
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            LiquidGlassButton(L10n.text("journal_share"), icon: "square.and.arrow.up", style: .secondary, haptic: .light, isFullWidth: true) {
                Task { await generateAndShareImage() }
            }.disabled(isGeneratingShare)

            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill").font(.system(size: 13, weight: .semibold))
                    Text(L10n.text("action_delete")).font(.system(size: 14, weight: .bold, design: .rounded))
                }.foregroundStyle(AppTheme.ember).frame(maxWidth: .infinity).frame(height: 44)
                    .background(AppTheme.ember.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.ember.opacity(0.2), lineWidth: 0.5))
            }.buttonStyle(.plain)
        }
    }

    // MARK: - Helpers
    private func travelModeIcon(_ rawValue: String) -> String {
        switch rawValue {
        case "car": return "car.fill"; case "walking": return "figure.walk"
        case "cycling": return "bicycle"; case "transit": return "bus.fill"
        default: return "mappin.and.ellipse"
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600; let m = (Int(duration) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }; return "\(m)m"
    }

    private func formattedDistance(_ distance: Double) -> String {
        if distance >= 1000 { return String(format: "%.1f km", distance / 1000) }
        return String(format: "%.0f m", distance)
    }

    private var typeBadge: String {
        switch entry.typeRaw {
        case "trip": return L10n.text("journal_entry_trip")
        case "commute": return L10n.text("journal_entry_commute")
        case "explore": return L10n.text("journal_entry_explore")
        default: return entry.typeRaw
        }
    }

    private var typeColor: Color {
        switch entry.typeRaw {
        case "trip": return AppTheme.liquidAccent
        case "commute": return AppTheme.sunshine
        case "explore": return AppTheme.success
        default: return Color.white
        }
    }

    @ViewBuilder
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Actions
    private func saveNotes() async {
        var updatedEntry = entry
        updatedEntry.notes = notes.isEmpty ? nil : notes
        do { try await journalStore.updateEntry(updatedEntry); hasUnsavedNotes = false; HapticEngine.shared.success() }
        catch { HapticEngine.shared.warning() }
    }

    private func deleteEntry() async {
        do { try await journalStore.delete(entry); onDelete(entry.id); HapticEngine.shared.success(); dismiss() }
        catch { HapticEngine.shared.warning() }
    }

    private func generateAndShareImage() async {
        isGeneratingShare = true
        defer { isGeneratingShare = false }
        let renderer = ImageRenderer(content: JournalShareCard(entry: entry, routeSnapshot: routeSnapshot).frame(width: 400, height: 500))
        if let image = renderer.uiImage { shareImage = image; showShareSheet = true }
    }
}

// MARK: - Journal Share Card
struct JournalShareCard: View {
    let entry: JournalEntry
    let routeSnapshot: RouteSnapshot?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0A0A1A"), Color(hex: "#1A1A2E")], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "map.fill").font(.system(size: 28))
                        .foregroundStyle(.linearGradient(colors: [AppTheme.liquidAccent, Color(hex: "#00D9FF")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(entry.title).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white).multilineTextAlignment(.center).lineLimit(2)
                    Text(entry.date.formatted(date: .long, time: .shortened)).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
                }
                if let route = routeSnapshot {
                    Divider().background(.white.opacity(0.1))
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text(formattedDuration(route.totalDuration)).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
                            Text("Duration").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
                        }.frame(maxWidth: .infinity)
                        Divider().background(.white.opacity(0.1)).frame(height: 40)
                        VStack(spacing: 4) {
                            Text(formattedDistance(route.totalDistance)).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
                            Text("Distance").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
                        }.frame(maxWidth: .infinity)
                        Divider().background(.white.opacity(0.1)).frame(height: 40)
                        VStack(spacing: 4) {
                            Text("\(route.safetyScore)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(safetyColor(route.safetyScore))
                            Text("Safety").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.4))
                        }.frame(maxWidth: .infinity)
                    }
                }
                Spacer()
                HStack {
                    Image(systemName: "cloud.sun.fill").font(.system(size: 12)).foregroundStyle(AppTheme.liquidAccent)
                    Text("ForeWiz").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Text("github.com/burak-bilgen/ForeWiz").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.3))
                }
            }.padding(24)
        }.frame(width: 400, height: 500).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600; let m = (Int(duration) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }; return "\(m)m"
    }

    private func formattedDistance(_ distance: Double) -> String {
        if distance >= 1000 { return String(format: "%.1f km", distance / 1000) }
        return String(format: "%.0f m", distance)
    }

    private func safetyColor(_ score: Int) -> Color {
        switch score { case 80...100: return AppTheme.success; case 60..<80: return AppTheme.sunshine; case 40..<60: return AppTheme.warning; default: return AppTheme.ember }
    }
}
