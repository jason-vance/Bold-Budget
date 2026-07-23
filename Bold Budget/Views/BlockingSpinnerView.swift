//
//  BlockingSpinnerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import SwiftUI

struct BlockingSpinnerView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.appBackground)
                .ignoresSafeArea()
            VStack(spacing: 8) {
                ProgressView()
                    .tint(Color.brandTeal)
            }
        }
        .id("BlockingSpinnerView")
    }
}

#Preview {
    BlockingSpinnerView()
}
