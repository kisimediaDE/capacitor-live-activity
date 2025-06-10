//
//  TaxiLiveActivityView.swift
//  App
//
//  Created by Simon Kirchner on 10.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TaxiLiveActivityView: View {
    let context: ActivityViewContext<GenericAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
            VStack(alignment: .leading) {
                Text(context.state.values["status"] ?? "")
                    .bold()
                Text(context.state.values["driver"] ?? "")
                    .font(.caption)
            }
            Spacer()
        }
        .padding()
    }
}
