//
//  EggTimerLiveActivityView.swift
//  App
//
//  Created by Simon Kirchner on 10.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EggTimerLiveActivityView: View {
    let context: ActivityViewContext<GenericAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "timer.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(context.state.values["remaining"] ?? "--:--")
                        .font(.system(.largeTitle, design: .monospaced))
                        .bold()
                }
            }

            if let stage = context.state.values["stage"], !stage.isEmpty {
                Text(stage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
