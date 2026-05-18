import SwiftUI

// MARK: - AI Briefing Section
/// Apple Weather'de OLMAYAN özellikler: hava durumu hikayesi, sağlık analizi, karşılaştırmalı anomali.
/// ForeWiz, yapay zekayla hava durumunu yorumlayıp kullanıcıya anlamlı içgörüler sunar.
struct AIBriefingSection: View {
    let briefing: DailyWeatherBriefing

    var body: some View {
        VStack(spacing: 14) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.liquidAccent)
                Text(L10n.text("briefing_section_title"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text(briefing.narrative.moodLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(moodColor(briefing.narrative.moodScore))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(moodColor(briefing.narrative.moodScore).opacity(0.12), in: Capsule())
            }

            // Narrative Card — the "story" of today's weather
            NarrativeCard(narrative: briefing.narrative)

            // Key Takeaway
            TakeawayCard(text: briefing.keyTakeaway)

            // Health Card
            HealthCard(health: briefing.health)

            // Comparative Card
            ComparativeCard(comparative: briefing.comparative)

            // Action Items
            ActionItemsCard(items: briefing.actionItems)
        }
    }

    private func moodColor(_ score: Int) -> Color {
        switch score {
        case 7...10: return AppTheme.success
        case 4..<7: return AppTheme.warning
        default: return AppTheme.danger
        }
    }
}

// MARK: - Narrative Card

private struct NarrativeCard: View {
    let narrative: WeatherNarrative

    private var personalityIcon: String {
        switch narrative.personality {
        case .energetic: return "sun.max.fill"
        case .melancholic: return "cloud.drizzle.fill"
        case .serene: return "wind"
        case .dramatic: return "cloud.bolt.fill"
        case .cozy: return "flame.fill"
        case .refreshing: return "snowflake"
        case .stubborn: return "cloud.sun.fill"
        case .lazy: return "humidity.fill"
        case .adventurous: return "wind.snow"
        case .mysterious: return "cloud.fog.fill"
        }
    }

    private var personalityColor: Color {
        switch narrative.personality {
        case .energetic: return AppTheme.sunshine
        case .melancholic: return AppTheme.sky
        case .serene: return AppTheme.teal
        case .dramatic: return AppTheme.danger
        case .cozy: return AppTheme.ember
        case .refreshing: return AppTheme.sky
        case .stubborn: return AppTheme.warning
        case .lazy: return AppTheme.ember
        case .adventurous: return AppTheme.danger
        case .mysterious: return AppTheme.royalPurple
        }
    }

    var body: some View {
        LiquidGlassCard(accentColor: personalityColor) {
            VStack(alignment: .leading, spacing: 12) {
                // Personality badge + headline
                HStack(spacing: 8) {
                    Image(systemName: personalityIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(personalityColor)

                    Text(narrative.headline)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Story
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 10))
                        .foregroundStyle(personalityColor.opacity(0.4))
                        .padding(.top, 2)

                    Text(narrative.story)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Pro tip
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.warning)

                    Text(narrative.proTip)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

// MARK: - Takeaway Card

private struct TakeawayCard: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "target")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.success)

            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.success.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.success.opacity(0.12), lineWidth: 0.5)
        )
    }
}

// MARK: - Health Card

private struct HealthCard: View {
    let health: HealthWeatherAnalysis

    var body: some View {
        LiquidGlassCard(accentColor: AppTheme.teal) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.teal)
                    Text(L10n.text("health_card_title"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    // Overall health score
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(healthScoreColor(health.overallHealthScore))
                            .frame(width: 40, height: 4)
                        Text("\(health.overallHealthScore)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(healthScoreColor(health.overallHealthScore))
                    }
                }

                // Health summary
                Text(health.healthSummary)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Metric mini cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    HealthMetricView(
                        icon: "brain.head.profile",
                        color: healthRiskColor(health.migraineRisk),
                        label: L10n.text("health_metric_migraine"),
                        value: health.migraineLabel
                    )
                    HealthMetricView(
                        icon: "moon.zzz.fill",
                        color: healthScoreColor(health.sleepQuality * 10),
                        label: L10n.text("health_metric_sleep"),
                        value: health.sleepLabel
                    )
                    HealthMetricView(
                        icon: "figure.walk",
                        color: healthScoreColor(health.staminaIndex * 10),
                        label: L10n.text("health_metric_stamina"),
                        value: health.staminaLabel
                    )
                    HealthMetricView(
                        icon: "lungs.fill",
                        color: healthRiskColor(health.respiratoryIndex),
                        label: L10n.text("health_metric_respiratory"),
                        value: health.respiratoryLabel
                    )
                }
            }
        }
    }

    private func healthScoreColor(_ score: Int) -> Color {
        switch score {
        case 70...100: return AppTheme.success
        case 40..<70: return AppTheme.warning
        default: return AppTheme.danger
        }
    }

    private func healthRiskColor(_ index: Int) -> Color {
        switch index {
        case 0...2: return AppTheme.success
        case 3...5: return AppTheme.warning
        default: return AppTheme.danger
        }
    }
}

private struct HealthMetricView: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Comparative Card

private struct ComparativeCard: View {
    let comparative: ComparativeWeatherAnalysis

    private var anomalyIcon: String {
        guard let anomaly = comparative.temperatureAnomalyCelsius else { return "thermometer" }
        switch anomaly {
        case _ where anomaly >= 3: return "thermometer.sun.fill"
        case _ where anomaly <= -3: return "thermometer.snowflake"
        default: return "thermometer"
        }
    }

    private var anomalyColor: Color {
        guard let anomaly = comparative.temperatureAnomalyCelsius else { return .white.opacity(0.5) }
        switch anomaly {
        case _ where anomaly >= 3: return AppTheme.danger
        case _ where anomaly <= -3: return AppTheme.sky
        default: return AppTheme.success
        }
    }

    var body: some View {
        LiquidGlassCard(accentColor: AppTheme.royalPurple) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.royalPurple)
                    Text(L10n.text("comparative_card_title"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Anomaly highlight
                if let anomaly = comparative.temperatureAnomalyCelsius {
                    HStack(spacing: 10) {
                        Image(systemName: anomalyIcon)
                            .font(.system(size: 18))
                            .foregroundStyle(anomalyColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(comparative.anomalyLabel)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(anomalyColor)
                            Text(comparative.anomalyDescription)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(2)
                        }
                    }
                    .padding(10)
                    .background(anomalyColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Day over day + week pattern
                HStack(spacing: 10) {
                    // Day-over-day
                    VStack(alignment: .leading, spacing: 4) {
                        Label(L10n.text("comparative_metric_dod"), systemImage: "arrow.left.arrow.right")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))

                        Text(comparative.dayOverDayChange)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .frame(width: 1, height: 32)
                        .overlay(.white.opacity(0.08))

                    // Week pattern
                    VStack(alignment: .leading, spacing: 4) {
                        Label(L10n.text("comparative_metric_pattern"), systemImage: "calendar")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))

                        Text(comparative.weekDescription)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Precipitation comparison
                HStack(spacing: 6) {
                    Image(systemName: comparative.isUnusuallyRainy ? "exclamationmark.cloud.fill" : "cloud.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(comparative.isUnusuallyRainy ? AppTheme.sky : .white.opacity(0.4))
                    Text(comparative.precipitationComparison)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(8)
                .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

// MARK: - Action Items Card

private struct ActionItemsCard: View {
    let items: [WeatherActionItem]

    var body: some View {
        LiquidGlassCard(accentColor: AppTheme.liquidAccent) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.liquidAccent)
                    Text(L10n.text("action_card_title"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                if items.isEmpty {
                    Text(L10n.text("action_card_empty"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.vertical, 4)
                } else {
                    ForEach(items.prefix(5)) { item in
                        ActionItemRow(item: item)
                        if item.id != items.prefix(5).last?.id {
                            Divider()
                                .overlay(.white.opacity(0.04))
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
    }
}

private struct ActionItemRow: View {
    let item: WeatherActionItem

    private var categoryColor: Color {
        switch item.category {
        case .timing: return AppTheme.teal
        case .health: return AppTheme.royalPurple
        case .outfit: return AppTheme.ember
        case .safety: return AppTheme.danger
        case .lifestyle: return AppTheme.success
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: item.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(item.description)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Text("#\(item.priority)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(categoryColor.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}
