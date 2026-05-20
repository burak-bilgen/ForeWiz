import SwiftUI

// MARK: - Day Key Events View

struct DayKeyEventsView: View {
    let events: [DayKeyEvent]

    /// Yalnızca moderate+ severity olaylar gösterilir (yağmur, sıcak, rüzgar, UV, fırtına).
    /// bestWindow gibi low-severity olaylar HeroCard özetinde zaten yer alıyor.
    private var visibleEvents: [DayKeyEvent] {
        events.filter { $0.severity >= .moderate }
    }

    private var accentColor: Color {
        guard let top = visibleEvents.first else {
            return AppTheme.liquidAccent
        }
        switch top.severity {
        case .critical: return AppTheme.coral
        case .high: return AppTheme.ember
        case .moderate: return AppTheme.sunshine
        case .low: return AppTheme.success
        }
    }

    @ViewBuilder
    var body: some View {
        if !visibleEvents.isEmpty {
            LiquidGlassCard(accentColor: accentColor, innerPadding: 0) {
                VStack(spacing: 0) {
                    // Header — compact
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accentColor)

                        Text(L10n.text("keyevent_header"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .textCase(.uppercase)

                        Spacer(minLength: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Events (max 3)
                    VStack(spacing: 6) {
                        ForEach(visibleEvents.prefix(3)) { event in
                            EventRow(event: event)
                                .padding(.horizontal, 12)
                        }
                    }

                    Color.clear.frame(height: 8)
                }
            }
        }
    }
}

// MARK: - Event Row (Severity: moderate+)

private struct EventRow: View {
    let event: DayKeyEvent

    private var severityColor: Color {
        switch event.severity {
        case .critical: return AppTheme.coral
        case .high: return AppTheme.ember
        case .moderate: return AppTheme.sunshine
        case .low: return AppTheme.success
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(severityColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: event.symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(severityColor)
            }
            .frame(width: 40, height: 40)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(event.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(event.timeDisplay)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .environment(\.colorScheme, .dark)
                        )
                }
                Text(event.description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            // Severity badge
            if event.severity >= .high {
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
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.05))
        )
    }
}


