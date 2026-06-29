import Foundation

struct WeatherNarrativeService {

    func generateNarrative(
        snapshot: WeatherSnapshot,
        recommendation: DailyRecommendation,
        calendar: Calendar = .current
    ) -> WeatherNarrative {
        let current = snapshot.current
        let apparentTemp = current.apparentTemperatureCelsius
        let condition = current.conditionCode?.lowercased() ?? ""
        let isDaylight = current.isDaylight ?? true
        let humidity = current.humidity ?? 0.5
        let windSpeed = current.windSpeedKph ?? 0
        let uvIndex = current.uvIndex ?? 0
        let hasRain = recommendation.risks.contains { $0.type == .rain && $0.severity >= .low }
        let hasHeat = recommendation.risks.contains { $0.type == .heat && $0.severity >= .low }
        let hasCold = recommendation.risks.contains { $0.type == .cold && $0.severity >= .low }
        let hasStorm = recommendation.risks.contains { $0.type == .storm && $0.severity >= .low }
        let hasWindRisk = recommendation.risks.contains { $0.type == .wind && $0.severity >= .low }

        let personality = determinePersonality(
            apparentTemp: apparentTemp,
            condition: condition,
            hasRain: hasRain,
            hasStorm: hasStorm,
            hasWindRisk: hasWindRisk,
            isDaylight: isDaylight,
            humidity: humidity,
            hour: calendar.component(.hour, from: current.date)
        )

        let headline = generateHeadline(
            apparentTemp: apparentTemp,
            condition: condition,
            personality: personality,
            isDaylight: isDaylight,
            todayScore: recommendation.outdoorScore.rawValue
        )

        let story = generateStory(
            apparentTemp: apparentTemp,
            condition: condition,
            personality: personality,
            humidity: humidity,
            windSpeed: windSpeed,
            hasRain: hasRain,
            hasHeat: hasHeat,
            hasCold: hasCold,
            hasStorm: hasStorm,
            score: recommendation.outdoorScore.rawValue,
            decision: recommendation.outdoorDecision,
            hour: calendar.component(.hour, from: current.date)
        )

        let proTip = generateProTip(
            apparentTemp: apparentTemp,
            condition: condition,
            hasRain: hasRain,
            hasHeat: hasHeat,
            hasCold: hasCold,
            hasStorm: hasStorm,
            uvIndex: uvIndex,
            windSpeed: windSpeed,
            bestWindow: recommendation.bestOutdoorWindow
        )

        let moodScore = calculateMoodScore(
            score: recommendation.outdoorScore.rawValue,
            apparentTemp: apparentTemp,
            hasStorm: hasStorm,
            hasRain: hasRain
        )

        let moodLabel: String
        let moodSymbol: String
        switch moodScore {
        case 9...10:
            moodLabel = L10n.text("narrative_mood_perfect")
            moodSymbol = "face.smiling.fill"
        case 7..<9:
            moodLabel = L10n.text("narrative_mood_great")
            moodSymbol = "face.smiling"
        case 5..<7:
            moodLabel = L10n.text("narrative_mood_okay")
            moodSymbol = "face.neutral"
        case 3..<5:
            moodLabel = L10n.text("narrative_mood_meh")
            moodSymbol = "face.dashed"
        default:
            moodLabel = L10n.text("narrative_mood_rough")
            moodSymbol = "cloud.bolt.fill"
        }

        return WeatherNarrative(
            headline: headline,
            personality: personality,
            story: story,
            proTip: proTip,
            moodScore: moodScore,
            moodLabel: moodLabel,
            moodSymbol: moodSymbol
        )
    }

    private func determinePersonality(
        apparentTemp: Double,
        condition: String,
        hasRain: Bool,
        hasStorm: Bool,
        hasWindRisk: Bool,
        isDaylight: Bool,
        humidity: Double,
        hour: Int
    ) -> WeatherNarrative.WeatherPersonality {
        if hasStorm || condition.contains("thunder") {
            return .dramatic
        }
        if condition.contains("fog") || condition.contains("haze") || condition.contains("mist") {
            return .mysterious
        }
        if hasWindRisk || apparentTemp >= 35 {
            return .adventurous
        }
        if hasRain && !isDaylight {
            return .melancholic
        }
        if hasRain {
            return .refreshing
        }
        if apparentTemp >= 30 && humidity >= 0.6 {
            return .lazy
        }
        if apparentTemp <= 5 {
            return .cozy
        }
        if apparentTemp <= 12 {
            return .serene
        }
        if apparentTemp >= 22 && apparentTemp < 30 && isDaylight {
            return .energetic
        }
        if hasRain == false && hasStorm == false && apparentTemp >= 15 && apparentTemp < 22 {
            return .serene
        }

        if hour < 8 || hour > 20 {
            return .serene
        }

        return .stubborn
    }

    private func generateHeadline(
        apparentTemp: Double,
        condition: String,
        personality: WeatherNarrative.WeatherPersonality,
        isDaylight: Bool,
        todayScore: Int
    ) -> String {
        switch personality {
        case .energetic:
            return L10n.text("narrative_headline_energetic")
        case .melancholic:
            return L10n.text("narrative_headline_melancholic")
        case .serene:
            if todayScore >= 80 {
                return L10n.text("narrative_headline_serene_perfect")
            }
            return L10n.text("narrative_headline_serene")
        case .dramatic:
            return L10n.text("narrative_headline_dramatic")
        case .cozy:
            return L10n.text("narrative_headline_cozy")
        case .refreshing:
            return L10n.text("narrative_headline_refreshing")
        case .stubborn:
            return L10n.text("narrative_headline_stubborn")
        case .lazy:
            return L10n.text("narrative_headline_lazy")
        case .adventurous:
            return L10n.text("narrative_headline_adventurous")
        case .mysterious:
            return L10n.text("narrative_headline_mysterious")
        }
    }

    private func generateStory(
        apparentTemp: Double,
        condition: String,
        personality: WeatherNarrative.WeatherPersonality,
        humidity: Double,
        windSpeed: Double,
        hasRain: Bool,
        hasHeat: Bool,
        hasCold: Bool,
        hasStorm: Bool,
        score: Int,
        decision: OutdoorDecision,
        hour: Int
    ) -> String {

        let contextPart = buildWeatherContext(
            apparentTemp: apparentTemp,
            condition: condition,
            humidity: humidity,
            windSpeed: windSpeed,
            hasRain: hasRain,
            hour: hour
        )

        let storyPart = getPersonalityStory(
            personality: personality,
            score: score,
            decision: decision
        )

        let scoreContext = buildScoreContext(score: score)

        if !scoreContext.isEmpty {
            return "\(contextPart) \(storyPart) \(scoreContext)"
        }
        return "\(contextPart) \(storyPart)"
    }

    private func buildWeatherContext(
        apparentTemp: Double,
        condition: String,
        humidity: Double,
        windSpeed: Double,
        hasRain: Bool,
        hour: Int
    ) -> String {
        let tempKey: String
        switch apparentTemp {
        case ..<5: tempKey = "narrative_dynamic_temp_cold"
        case 5..<15: tempKey = "narrative_dynamic_temp_cool"
        case 15..<22: tempKey = "narrative_dynamic_temp_ideal"
        case 22..<30: tempKey = "narrative_dynamic_temp_warm"
        default: tempKey = "narrative_dynamic_temp_hot"
        }
        let tempDesc = String(format: L10n.text(tempKey), Int(apparentTemp))

        let windKey: String
        if hasRain && windSpeed < 5 {
            windKey = "narrative_dynamic_wind_calm"
        } else if windSpeed < 10 {
            windKey = "narrative_dynamic_wind_calm"
        } else if windSpeed < 25 {
            windKey = "narrative_dynamic_wind_light"
        } else if windSpeed < 40 {
            windKey = "narrative_dynamic_wind_moderate"
        } else {
            windKey = "narrative_dynamic_wind_strong"
        }
        let windDesc = L10n.text(windKey)

        let humidityDesc: String
        if humidity >= 0.7 {
            humidityDesc = String(format: L10n.text("narrative_dynamic_humidity_high"), Int(humidity * 100))
        } else if humidity <= 0.35 {
            humidityDesc = L10n.text("narrative_dynamic_humidity_low")
        } else {
            humidityDesc = ""
        }

        let timeGreeting: String
        if hour < 10 {
            timeGreeting = L10n.text("narrative_dynamic_morning")
        } else if hour >= 19 {
            timeGreeting = L10n.text("narrative_dynamic_evening")
        } else {
            timeGreeting = ""
        }

        let connector = L10n.text("narrative_dynamic_context_connector")

        var parts: [String] = []
        if !timeGreeting.isEmpty {
            parts.append(timeGreeting)
        }
        parts.append(tempDesc)
        parts.append(windDesc)
        if !humidityDesc.isEmpty {
            parts.append(humidityDesc)
        }

        return parts.joined(separator: " ") + connector
    }

    private func getPersonalityStory(
        personality: WeatherNarrative.WeatherPersonality,
        score: Int,
        decision: OutdoorDecision
    ) -> String {

        if score >= 80 {
            return L10n.text("narrative_story_serene_perfect")
        }

        switch personality {
        case .energetic: return L10n.text("narrative_story_energetic")
        case .melancholic: return L10n.text("narrative_story_melancholic")
        case .serene: return L10n.text("narrative_story_serene")
        case .dramatic: return L10n.text("narrative_story_dramatic")
        case .cozy: return L10n.text("narrative_story_cozy")
        case .refreshing: return L10n.text("narrative_story_refreshing")
        case .stubborn: return L10n.text("narrative_story_stubborn")
        case .lazy: return L10n.text("narrative_story_lazy")
        case .adventurous: return L10n.text("narrative_story_adventurous")
        case .mysterious: return L10n.text("narrative_story_mysterious")
        }
    }

    private func buildScoreContext(score: Int) -> String {

        if score >= 75 {
            return String(format: L10n.text("narrative_dynamic_score_high"), score)
        } else if score <= 30 {
            return String(format: L10n.text("narrative_dynamic_score_low"), score)
        }
        return ""
    }

    private func generateProTip(
        apparentTemp: Double,
        condition: String,
        hasRain: Bool,
        hasHeat: Bool,
        hasCold: Bool,
        hasStorm: Bool,
        uvIndex: Int,
        windSpeed: Double,
        bestWindow: TimeWindow?
    ) -> String {
        if hasStorm {
            return L10n.text("narrative_tip_storm")
        }
        if hasHeat && uvIndex >= 7 {
            return L10n.text("narrative_tip_heat_uv")
        }
        if hasHeat {
            return L10n.text("narrative_tip_heat")
        }
        if hasRain, let window = bestWindow {
            return String(format: L10n.text("narrative_tip_rain_window"), window.shortDisplayText)
        }
        if hasCold {
            return L10n.text("narrative_tip_cold")
        }
        if uvIndex >= 6 {
            return L10n.text("narrative_tip_uv")
        }
        if windSpeed >= 30 {
            return L10n.text("narrative_tip_wind")
        }
        if let window = bestWindow {
            return String(format: L10n.text("narrative_tip_best_window"), window.shortDisplayText)
        }
        return L10n.text("narrative_tip_enjoy")
    }

    private func calculateMoodScore(
        score: Int,
        apparentTemp: Double,
        hasStorm: Bool,
        hasRain: Bool
    ) -> Int {
        var mood = score / 10

        if hasStorm {
            mood -= 3
        }

        if apparentTemp >= 38 || apparentTemp <= 0 {
            mood -= 2
        } else if apparentTemp >= 35 || apparentTemp <= 3 {
            mood -= 1
        }

        if (18...26).contains(apparentTemp) && !hasRain {
            mood += 1
        }

        return max(1, min(10, mood))
    }
}
