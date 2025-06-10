//
//  DeliveryLiveActivityView.swift
//  App
//
//  Created by Simon Kirchner on 10.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DeliveryLiveActivityView: View {
    let context: ActivityViewContext<GenericAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.values["status"] ?? "")
                    .bold()
                
                Text(context.state.values["eta"] ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}
