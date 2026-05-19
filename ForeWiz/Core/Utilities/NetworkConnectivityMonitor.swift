import Foundation
import Network
import OSLog

final class NetworkConnectivityMonitor {
    static let shared = NetworkConnectivityMonitor()
    private let logger = AppLogger.network
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.forewiz.network-monitor", qos: .utility)
    private var isMonitoring = false
    private var lastKnownStatus: NetworkStatus = .unknown

    private init() {}

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitor.pathUpdateHandler = { [weak self] path in
            let newStatus: NetworkStatus = path.status == .satisfied ? .reachable : .notReachable
            let oldStatus = self?.lastKnownStatus ?? .unknown
            if newStatus != oldStatus {
                self?.logger.info("Network status changed: \(oldStatus.rawValue) -> \(newStatus.rawValue)")
                self?.lastKnownStatus = newStatus
                if newStatus == .reachable {
                    NotificationCenter.default.post(name: .networkDidBecomeReachable, object: nil)
                } else {
                    NotificationCenter.default.post(name: .networkDidBecomeUnreachable, object: nil)
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }

    var currentStatus: NetworkStatus {
        monitor.currentPath.status == .satisfied ? .reachable : .notReachable
    }

    var isReachable: Bool {
        currentStatus == .reachable
    }
}

enum NetworkStatus: String {
    case reachable, notReachable, unknown
}

extension Notification.Name {
    static let networkDidBecomeReachable = Notification.Name("networkDidBecomeReachable")
    static let networkDidBecomeUnreachable = Notification.Name("networkDidBecomeUnreachable")
}
