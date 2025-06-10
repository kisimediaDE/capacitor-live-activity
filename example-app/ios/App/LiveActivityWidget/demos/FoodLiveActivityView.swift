//
//  FoodLiveActivityView.swift
//  App
//
//  Created by Simon Kirchner on 10.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FoodLiveActivityView: View {
    let context: ActivityViewContext<GenericAttributes>

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(context.state.values["status"] ?? "")
                    .font(.headline)
                    .bold()
                
                if let step = context.state.values["step"], !step.isEmpty {
                    Text(step)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                if let eta = context.state.values["eta"], !eta.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(eta)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
    }
}
