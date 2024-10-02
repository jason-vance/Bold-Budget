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
            .frame(height: 0.25)
            .foregroundStyle(Color.text)
            .opacity(0.25)
    }
}

#Preview {
    BarDivider()
}
