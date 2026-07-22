//
//  BarDivider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import SwiftUI

struct BarDivider: View {
    var body: some View {
        Rectangle()
            .fill(.appMutedText.opacity(0.3))
            .frame(height: 1)
    }
}

#Preview {
    BarDivider()
}
