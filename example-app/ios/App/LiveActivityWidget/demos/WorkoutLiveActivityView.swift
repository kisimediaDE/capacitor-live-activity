//
//  WorkoutLiveActivityView.swift
//  App
//
//  Created by Simon Kirchner on 10.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutLiveActivityView: View {
    let context: ActivityViewContext<GenericAttributes>

    var body: some View {
        VStack {
            Text(context.state.values["distance"] ?? "")
                .font(.title)
            HStack {
                Text(context.state.values["duration"] ?? "")
                Spacer()
                Text(context.state.values["pace"] ?? "")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}
