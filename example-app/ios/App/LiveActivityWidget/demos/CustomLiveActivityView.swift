//
//  CustomLiveActivityView.swift
//  App
//
//  Created by Simon Kirchner on 10.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CustomLiveActivityView: View {
    let context: ActivityViewContext<GenericAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(context.state.values.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Text(key.capitalized + ":")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(value)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .font(.footnote)
            }
        }
        .padding()
    }
}
