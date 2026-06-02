import SwiftUI
import WizPathKit

// MARK: - Day Key Events View

struct DayKeyEventsView: View {
    let events: [DayKeyEvent]

    /// Önemli event'ler: severity >= moderate olan riskler + alwaysShow event'leri (bestWindow, improving)
    private var visibleEvents: [DayKeyEvent] {
        events.filter { $0.severity >= .moderate || $0.alwaysShow }
    }

    /// Eğer moderate+ bir risk yoksa ama info event'ler varsa, onları göster
    private var hasRealRisks: Bool {
        visibleEvents.contains { !$0.isPositive && $0.severity >= .moderate }
    }

    /// Info/positive event'ler (bestWindow, improving) - sadece hiç risk yoksa gösterilir
    private var infoEvents: [DayKeyEvent] {
        visibleEvents.filter { $0.isPositive }
    }

    /// Risk event'leri (rain, storm, heat, cold, wind, uv, snow, fog)
    private var riskEvents: [DayKeyEvent] {
        visibleEvents.filter { !$0.isPositive }
    }

    /// Gösterilecek event listesi: önce riskler (severity sıralı), sonra info event'ler
    private var displayEvents: [DayKeyEvent] {
        riskEvents + infoEvents
    }

    /// Max gösterilecek event sayısı (kalan için "view all" göster)
    private let maxVisible = 5

    /// Genişletilmiş view state
    @State private var showAll = false

    private var accentColor: Color {
        guard let top = displayEvents.first else {
            return AppTheme.liquidAccent
        }
        if top.isPositive {
            return AppTheme.success
        }
        switch top.severity {
        case .critical: return AppTheme.coral
        case .high: return AppTheme.ember
        case .moderate: return AppTheme.sunshine
        case .low, .info: return AppTheme.success
        }
    }

    /// Event'in belirtilen max hesaplamalarına göre gösterilecekleri döndür
    private var eventsToShow: [DayKeyEvent] {
        showAll ? displayEvents : Array(displayEvents.prefix(maxVisible))
    }

    private var hiddenCount: Int {
        max(0, displayEvents.count - maxVisible)
    }

    @ViewBuilder
    var body: some View {
        if !displayEvents.isEmpty {
            LiquidGlassCard(accentColor: accentColor, innerPadding: 0) {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: hasRealRisks ? "bell.badge.fill" : "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accentColor)

                        Text(L10n.text("keyevent_header"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .textCase(.uppercase)
                            .layoutPriority(1)

                        Spacer(minLength: 4)

                        // Live indicator dot
                        Circle()
                            .fill(accentColor)
                            .frame(width: 6, height: 6)
                            .opacity(0.6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // Events
                    VStack(spacing: 6) {
                        ForEach(eventsToShow) { event in
                            EventRow(event: event)
                                .padding(.horizontal, 12)
                        }

                        // "View all" button
                        if hiddenCount > 0 && !showAll {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showAll = true
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(String(format: L10n.text("keyevent_show_more"), hiddenCount))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(accentColor.opacity(0.8))
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(accentColor.opacity(0.08))
                                )
                                .padding(.horizontal, 12)
                            }
                            .buttonStyle(.plain)
                        }

                        // Collapse button
                        if showAll && hiddenCount > 0 {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showAll = false
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(L10n.text("keyevent_show_less"))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Color.clear.frame(height: 8)
                }
            }
        }
    }
}

// MARK: - Event Row

private struct EventRow: View {
    let event: DayKeyEvent

    private var severityColor: Color {
        if event.isPositive {
            return AppTheme.success
        }
        switch event.severity {
        case .critical: return AppTheme.coral
        case .high: return AppTheme.ember
        case .moderate: return AppTheme.sunshine
        case .low, .info: return AppTheme.success
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent stripe — intensity matches severity
            if !event.isPositive && event.severity >= .high {
                Rectangle()
                    .fill(severityColor)
                    .frame(width: 3)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14, bottomLeadingRadius: 14,
                            bottomTrailingRadius: 0, topTrailingRadius: 0
                        )
                    )
            } else if event.isPositive {
                Rectangle()
                    .fill(severityColor.opacity(0.4))
                    .frame(width: 3)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14, bottomLeadingRadius: 14,
                            bottomTrailingRadius: 0, topTrailingRadius: 0
                        )
                    )
            }

            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(severityColor.opacity(event.isPositive ? 0.08 : 0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: event.symbolName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(severityColor)
                }
                .frame(width: 40, height: 40)

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(event.description)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(event.isPositive ? severityColor.opacity(0.7) : .white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                // Severity badge (sadece risk event'leri için)
                if !event.isPositive && event.severity >= .high {
                    Text(event.severity == .critical ? L10n.text("keyevent_critical") : L10n.text("keyevent_high"))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(severityColor)
                        )
                        .fixedSize()
                }

                // Info badge (positive events)
                if event.isPositive {
                    Text(L10n.text("keyevent_info_badge"))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(severityColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(severityColor.opacity(0.15))
                        )
                        .fixedSize()
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(event.isPositive ? severityColor.opacity(0.04) : .white.opacity(0.05))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
