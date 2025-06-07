//
//  LiveActivityWidgetLiveActivity.swift
//  LiveActivityWidget
//
//  Created by Simon Kirchner on 07.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GenericAttributes.self) { context in
            // Lock screen UI (Banner, Sperrbildschirm)
            VStack {
                Text("📡 Live Activity")
                    .font(.headline)
                Divider()
                ForEach(context.state.values.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text("\(key):")
                            .fontWeight(.bold)
                        Text(value)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(.blue)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.values["title"] ?? "⏱")
                        .font(.title3)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.values["status"] ?? "-")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.values["message"] ?? "")
                        .font(.footnote)
                }
            } compactLeading: {
                Text("🔔")
            } compactTrailing: {
                Text(context.state.values["status"] ?? "")
            } minimal: {
                Text("🎯")
            }
        }
    }
}
