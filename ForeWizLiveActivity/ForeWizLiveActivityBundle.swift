import SwiftUI
import WidgetKit

@main
struct ForeWizLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 18.0, *) {
            ForeWizLiveActivity()
        }
    }
}
