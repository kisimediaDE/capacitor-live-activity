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
                if let data = context.state.imageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.title)
                        .font(.headline)

                    if let subtitle = context.state.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let end = context.state.timerEndDate {
                    Text("Ends at \(end.formatted(date: .omitted, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            }
            .padding()
            .activityBackgroundTint(Color.white)
            .activitySystemActionForegroundColor(Color.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if let data = context.state.imageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.title)
                            .font(.headline)

                        if let subtitle = context.state.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let end = context.state.timerEndDate {
                        Text(end.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            } compactLeading: {
                Image(systemName: "clock.fill")
            } compactTrailing: {
                if let end = context.state.timerEndDate {
                    Text(end.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                } else {
                    Text("⏱")
                }
            } minimal: {
                Image(systemName: "bolt.circle")
            }
        }
    }
}
