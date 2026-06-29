import Foundation
import ActivityKit

@available(iOS 18.0, *)
public final class WizPathHUDManager: @unchecked Sendable {

    nonisolated(unsafe) public static let shared = WizPathHUDManager()

    nonisolated(unsafe) private var currentActivity: Activity<WizPathHUDLiveActivityAttributes>?

    private init() {}

    public func startRouteActivity(
        origin: String,
        destination: String,
        mode: TravelMode
    ) async {
        await endRouteActivity()

        let attributes = WizPathHUDLiveActivityAttributes(
            routeOriginName: origin,
            routeDestinationName: destination,
            travelModeRaw: mode.rawValue
        )

        let initialState = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 100,
            hazardCount: 0,
            totalDuration: 0,
            distanceRemaining: 0,
            nextSafeStopName: nil,
            nextSafeStopEta: nil,
            routeRiskLabel: "Calculating...",
            weatherConditionSymbol: "questionmark",
            estimatedArrival: Date()
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            currentActivity = activity
        } catch {
            currentActivity = nil
        }
    }

    public func updateHUD(with state: WizPathHUDLiveActivityAttributes.ContentState) async {
        guard let activity = currentActivity else { return }
        await activity.update(.init(state: state, staleDate: nil))
    }

    public func endRouteActivity() async {
        guard let activity = currentActivity else { return }
        await activity.end(dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
