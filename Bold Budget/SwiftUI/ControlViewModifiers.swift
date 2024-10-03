//
//  ControlViewModifiers.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Foundation
import SwiftUI

extension View {
    
    func buttonLabelSmall() -> some View {
        self
            .foregroundStyle(Color.text)
            .padding(.horizontal, .paddingHorizontalButtonSmall)
            .padding(.vertical, .paddingVerticalButtonSmall)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                    .foregroundStyle(Color.text.opacity(Double.opacityButtonBackground))
            }
    }
    
    func buttonLabelMedium() -> some View {
        self
            .foregroundStyle(Color.text)
            .padding(.horizontal, .paddingHorizontalButtonMedium)
            .padding(.vertical, .paddingVerticalButtonMedium)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.text.opacity(Double.opacityButtonBackground))
            }
    }
    
    func textFieldSmall() -> some View {
        self
            .foregroundStyle(Color.text)
            .tint(Color.text)
            .padding(.horizontal, .paddingHorizontalButtonSmall)
            .padding(.vertical, .paddingHorizontalButtonSmall)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                    .stroke(style: .init(lineWidth: .borderWidthMedium))
                    .foregroundStyle(Color.text.opacity(Double.opacityButtonBackground))
            }
    }
    
    func dashboardTransactionRow() -> some View {
        self
            .listRowBackground(Color.text.opacity(.opacityButtonBackground))
            .listRowSeparatorTint(Color.text.opacity(.opacityButtonBackground))
            .listRowInsets(.init(top: .paddingVerticalButtonXSmall,
                                 leading: .paddingHorizontalButtonXSmall,
                                 bottom: .paddingVerticalButtonXSmall,
                                 trailing: .paddingHorizontalButtonXSmall))
    }
    
    func formRow() -> some View {
        self
            .listRowBackground(Color.text.opacity(.opacityButtonBackground))
            .listRowSeparatorTint(Color.text.opacity(.opacityButtonBackground))
            .listRowInsets(.init(top: .paddingVerticalButtonXSmall,
                                 leading: 16,
                                 bottom: .paddingVerticalButtonXSmall,
                                 trailing: .paddingHorizontalButtonXSmall))
    }
}
