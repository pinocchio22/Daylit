//
//  MyMemoWidgetLiveActivity.swift
//  MyMemoWidget
//
//  Created by JINHUN CHOI on 8/31/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct MyMemoWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MyMemoWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyMemoWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            if #available(iOS 18.0, *) {
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
            } else {
                DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        Text("Leading")
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        Text("Trailing")
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        Text("Bottom")
                    }
                } compactLeading: {
                    Text("L")
                } compactTrailing: {
                    Text("T")
                } minimal: {
                    Text("M")
                }
            }
        }
    }
}

private extension MyMemoWidgetAttributes {
    static var preview: MyMemoWidgetAttributes {
        MyMemoWidgetAttributes(name: "World")
    }
}

private extension MyMemoWidgetAttributes.ContentState {
    static var smiley: MyMemoWidgetAttributes.ContentState {
        MyMemoWidgetAttributes.ContentState(emoji: "😀")
    }

    static var starEyes: MyMemoWidgetAttributes.ContentState {
        MyMemoWidgetAttributes.ContentState(emoji: "🤩")
    }
}

@available(iOS 18.0, *)
#Preview("Notification", as: .content, using: MyMemoWidgetAttributes.preview) {
    MyMemoWidgetLiveActivity()
} contentStates: {
    MyMemoWidgetAttributes.ContentState.smiley
    MyMemoWidgetAttributes.ContentState.starEyes
}
