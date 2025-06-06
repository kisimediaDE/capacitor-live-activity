//
//  LiveActivityWidgetLiveActivity.swift
//  LiveActivityWidget
//
//  Created by Simon Kirchner on 06.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String?
        var timerEndDate: Date?
        var imageData: Data?
    }

    var id: String
}

struct LiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.title)
                        .font(.headline)

                    if let subtitle = context.state.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let end = context.state.timerEndDate {
                        Text("Ends at \(end.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                if let data = context.state.imageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .activityBackgroundTint(Color.white)
            .activitySystemActionForegroundColor(Color.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Text(context.state.title)
                        if let subtitle = context.state.subtitle {
                            Text(subtitle)
                        }
                    }
                }
            } compactLeading: {
                Text("▶")
            } compactTrailing: {
                Text("⏱")
            } minimal: {
                Text("🔔")
            }
        }
    }
}
