import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: DailyRecommendation

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ModernDetailHero(recommendation: recommendation)
                ModernDetailExplanation(explanation: recommendation.explanation)

                if !recommendation.bestActivityWindows.isEmpty {
                    ModernDetailActivityTimeline(activities: recommendation.bestActivityWindows)
                }

                ModernDetailOutfitCard(outfit: recommendation.outfit)

                if !recommendation.avoidWindows.isEmpty {
                    ModernDetailAvoidCard(avoidWindows: recommendation.avoidWindows)
                }

                if !recommendation.risks.isEmpty {
                    ModernDetailRiskList(risks: recommendation.risks)
                }
            }
            .padding(20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(L10n.text("recommendation_detail_title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ModernDetailHero: View {
    let recommendation: DailyRecommendation

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.outdoorDecision.localizedTitle)
                        .font(.system(size: 32, weight: .bold))
                    Text(recommendation.summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", recommendation.outdoorScore.displayValue))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("Skor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let bestWindow = recommendation.bestOutdoorWindow {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                    Text(bestWindow.shortDisplayText)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(24)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernDetailExplanation: View {
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Açıklama")
                .font(.headline)
            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernDetailActivityTimeline: View {
    let activities: [ActivityRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En İyi Zamanlar")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(activities) { activity in
                    ModernDetailActivityRow(activity: activity)
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernDetailActivityRow: View {
    let activity: ActivityRecommendation

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activityType.localizedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(activity.bestWindow.shortDisplayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%.1f", activity.score.displayValue))
                .font(.headline)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 8)
    }
}

private struct ModernDetailOutfitCard: View {
    let outfit: OutfitRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kıyafet Önerisi")
                .font(.headline)

            Text(outfit.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !outfit.items.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(outfit.items, id: \.self) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 20)
                            Text(item)
                                .font(.subheadline)
                        }
                    }
                }
            }

            if !outfit.accessories.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(outfit.accessories, id: \.self) { accessory in
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.blue)
                                .frame(width: 20)
                            Text(accessory)
                                .font(.subheadline)
                        }
                    }
                }
            }

            if let warning = outfit.warning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text(warning)
                        .font(.subheadline)
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernDetailAvoidCard: View {
    let avoidWindows: [AvoidWindowRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kaçınılması Gereken Zamanlar")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(avoidWindows) { warning in
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(warning.window.shortDisplayText) · \(warning.risk.title)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(warning.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernDetailRiskList: View {
    let risks: [WeatherRisk]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Riskler")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(risks) { risk in
                    ModernDetailRiskRow(risk: risk)
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernDetailRiskRow: View {
    let risk: WeatherRisk

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(risk.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(risk.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var iconName: String {
        switch risk.type {
        case .heat: return "thermometer.sun.fill"
        case .uv: return "sun.max.fill"
        case .rain: return "cloud.rain.fill"
        case .wind: return "wind"
        case .humidity: return "humidity.fill"
        case .cold: return "snowflake"
        case .storm: return "cloud.bolt.rain.fill"
        case .poorComfort: return "exclamationmark.circle.fill"
        case .pollen: return "leaf.fill"
        case .airQuality: return "aqi.medium"
        }
    }

    private var color: Color {
        switch risk.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .extreme: return .purple
        }
    }
}
