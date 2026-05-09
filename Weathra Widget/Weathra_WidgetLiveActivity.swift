//
//  Weathra_WidgetLiveActivity.swift
//  Weathra Widget
//
//  Created by Burak on 9.05.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Weathra_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Weathra_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Weathra_WidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Weathra_WidgetAttributes {
    fileprivate static var preview: Weathra_WidgetAttributes {
        Weathra_WidgetAttributes(name: "World")
    }
}

extension Weathra_WidgetAttributes.ContentState {
    fileprivate static var smiley: Weathra_WidgetAttributes.ContentState {
        Weathra_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Weathra_WidgetAttributes.ContentState {
         Weathra_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Weathra_WidgetAttributes.preview) {
   Weathra_WidgetLiveActivity()
} contentStates: {
    Weathra_WidgetAttributes.ContentState.smiley
    Weathra_WidgetAttributes.ContentState.starEyes
}
