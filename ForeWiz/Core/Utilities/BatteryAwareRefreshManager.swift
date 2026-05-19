import Foundation
import UIKit
import OSLog

final class BatteryAwareRefreshManager {
    static let shared = BatteryAwareRefreshManager()
    private let logger = AppLogger.lifecycle

    private var batteryLevel: Float {
        UIDevice.current.batteryLevel
    }

    private var batteryState: UIDevice.BatteryState {
        UIDevice.current.batteryState
    }

    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    deinit {
        UIDevice.current.isBatteryMonitoringEnabled = false
    }

    var shouldAllowBackgroundRefresh: Bool {
        let level = batteryLevel
        let state = batteryState

        if state == .charging || state == .full {
            return true
        }

        if level < 0 {
            return true
        }

        return level > 0.20
    }

    var refreshFrequency: TimeInterval {
        let level = batteryLevel
        let state = batteryState

        if state == .charging || state == .full {
            return 15 * 60
        }

        if level < 0.10 {
            return 60 * 60
        } else if level < 0.20 {
            return 30 * 60
        } else {
            return 15 * 60
        }
    }

    func logBatteryStatus() {
        let level = Int(batteryLevel * 100)
        let state = batteryState
        let allowed = shouldAllowBackgroundRefresh
        let frequency = refreshFrequency / 60

        logger.info("Battery: \(level)%, State: \(state)")
        logger.info("Background refresh allowed: \(allowed)")
        logger.info("Refresh frequency: \(frequency) minutes")
    }
}

extension UIDevice.BatteryState: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        @unknown default: return "unknown"
        }
    }
}
