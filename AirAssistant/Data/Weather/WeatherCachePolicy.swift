import Foundation

enum WeatherCacheFreshness: Equatable {
    case fresh
    case staleUsable
    case expired
}

struct WeatherCachePolicy {
    let freshInterval: TimeInterval
    let usableInterval: TimeInterval

    init(freshInterval: TimeInterval = 20 * 60, usableInterval: TimeInterval = 6 * 60 * 60) {
        self.freshInterval = freshInterval
        self.usableInterval = usableInterval
    }

    func freshness(for fetchedAt: Date, now: Date) -> WeatherCacheFreshness {
        let age = now.timeIntervalSince(fetchedAt)

        if age <= freshInterval {
            return .fresh
        }

        if age <= usableInterval {
            return .staleUsable
        }

        return .expired
    }
}
