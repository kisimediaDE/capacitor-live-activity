//
//  LiveActivityWidgetLiveActivity.swift
//  LiveActivityWidget
//
//  Created by Simon Kirchner on 07.06.25.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct LiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GenericAttributes.self) { context in
            switch context.attributes.staticValues["type"] {
            case "custom":
                CustomLiveActivityView(context: context)
            case "delivery":
                DeliveryLiveActivityView(context: context)
            case "taxi":
                TaxiLiveActivityView(context: context)
            case "food":
                FoodLiveActivityView(context: context)
            case "workout":
                WorkoutLiveActivityView(context: context)
            case "eggtimer":
                EggTimerLiveActivityView(context: context)
            default:
                CustomLiveActivityView(context: context)
            }
        } dynamicIsland: { context in
            let type = context.attributes.staticValues["type"]

            return DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    switch type {
                    case "delivery":
                        DeliveryLiveActivityView(context: context)
                    case "taxi":
                        TaxiLiveActivityView(context: context)
                    case "food":
                        FoodLiveActivityView(context: context)
                    case "workout":
                        WorkoutLiveActivityView(context: context)
                    case "eggtimer":
                        EggTimerLiveActivityView(context: context)
                    case "custom":
                        CustomLiveActivityView(context: context)
                    default:
                        CustomLiveActivityView(context: context)
                    }
                }
            } compactLeading: {
                Text("📦")
            } compactTrailing: {
                Text("⏱")
            } minimal: {
                Text("•")
            }
        }
    }
}
