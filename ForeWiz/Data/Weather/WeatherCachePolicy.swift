import Foundation

enum WeatherCacheFreshness: Equatable {
    case fresh
    case staleUsable
    case expired
}

struct WeatherCachePolicy {
    let baseFreshInterval: TimeInterval
    let baseUsableInterval: TimeInterval
    let minFreshInterval: TimeInterval
    let maxUsableInterval: TimeInterval

    init(
        freshInterval: TimeInterval = 20 * 60,
        usableInterval: TimeInterval = 6 * 60 * 60,
        minFreshInterval: TimeInterval = 10 * 60,
        maxUsableInterval: TimeInterval = 12 * 60 * 60
    ) {
        self.baseFreshInterval = freshInterval
        self.baseUsableInterval = usableInterval
        self.minFreshInterval = minFreshInterval
        self.maxUsableInterval = maxUsableInterval
    }

    func freshness(for fetchedAt: Date, now: Date) -> WeatherCacheFreshness {
        let age = now.timeIntervalSince(fetchedAt)

        if age <= baseFreshInterval {
            return .fresh
        }
        if age <= baseUsableInterval {
            return .staleUsable
        }
        return .expired
    }

    func freshness(for fetchedAt: Date, now: Date, hourlyTempRange: Double?) -> WeatherCacheFreshness {
        guard let range = hourlyTempRange else {
            return freshness(for: fetchedAt, now: now)
        }

        let age = now.timeIntervalSince(fetchedAt)

        if range >= 12 {
            let fresh = minFreshInterval
            let usable = baseUsableInterval * 0.5
            if age <= fresh { return .fresh }
            if age <= usable { return .staleUsable }
            return .expired
        }

        if range >= 6 {
            let fresh = baseFreshInterval * 0.8
            let usable = baseUsableInterval
            if age <= fresh { return .fresh }
            if age <= usable { return .staleUsable }
            return .expired
        }

        if age <= baseFreshInterval * 1.5 {
            return .fresh
        }
        if age <= maxUsableInterval {
            return .staleUsable
        }
        return .expired
    }
}
