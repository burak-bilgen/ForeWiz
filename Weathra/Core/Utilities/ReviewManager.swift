import Foundation
import StoreKit
import SwiftUI

@available(iOS 16.0, *)
final class ReviewManager {
    static let shared = ReviewManager()
    
    private let keyLastReviewRequest = "lastReviewRequestDate"
    private let keyReviewPromptCount = "reviewPromptCount"
    private let keyUserActionsCount = "userActionsCount"
    private let minimumActionsBeforePrompt = 5
    private let minimumDaysBetweenPrompts = 90
    
    private init() {}
    
    func logUserAction() {
        let currentCount = UserDefaults.standard.integer(forKey: keyUserActionsCount)
        UserDefaults.standard.set(currentCount + 1, forKey: keyUserActionsCount)
    }
    
    func requestReviewIfAppropriate() {
        let actions = UserDefaults.standard.integer(forKey: keyUserActionsCount)
        guard actions >= minimumActionsBeforePrompt else { return }
        
        if let lastRequest = UserDefaults.standard.object(forKey: keyLastReviewRequest) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day ?? 0
            guard daysSinceLastRequest >= minimumDaysBetweenPrompts else { return }
        }
        
        UserDefaults.standard.set(Date(), forKey: keyLastReviewRequest)
        UserDefaults.standard.set(0, forKey: keyUserActionsCount)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            AppStore.requestReview(in: windowScene)
        }
    }
}
