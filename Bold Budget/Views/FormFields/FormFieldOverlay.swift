//
//  FormFieldOverlay.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import SwiftUI

struct FormFieldOverlay: View {
    
    var action: () -> Void
    
    init(_ action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                .stroke(style: .init(lineWidth: .borderWidthMedium))
                .foregroundStyle(Color.text.opacity(.opacityButtonBackground))
        }
    }
}

#Preview {
    FormFieldOverlay {}
}
