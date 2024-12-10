//
//  ControlViewModifiers.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Foundation
import SwiftUI

extension View {
    
    func buttonSymbolCircleSmall(isProminent: Bool = false) -> some View {
        self
            .font(.caption2)
            .foregroundStyle(isProminent ? Color.text : Color.background)
            .padding(.paddingCircleButtonSmall)
            .background {
                Circle()
                    .foregroundStyle(Color.text)
                    .opacity(isProminent ? 1 : Double.opacityButtonBackground)
            }
    }
    
    func buttonLabelSmall(isProminent: Bool = false) -> some View {
        self
            .foregroundStyle(isProminent ? Color.background : Color.text)
            .padding(.horizontal, .paddingHorizontalButtonSmall)
            .padding(.vertical, .paddingVerticalButtonSmall)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                    .foregroundStyle(Color.text)
                    .opacity(isProminent ? 1 : Double.opacityButtonBackground)
            }
    }
    
    func buttonLabelMedium(isProminent: Bool = false) -> some View {
        self
            .foregroundStyle(isProminent ? Color.background : Color.text)
            .padding(.horizontal, .paddingHorizontalButtonMedium)
            .padding(.vertical, .paddingVerticalButtonMedium)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.text)
                    .opacity(isProminent ? 1 : Double.opacityButtonBackground)
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
                                 leading: .paddingHorizontalButtonMedium,
                                 bottom: .paddingVerticalButtonXSmall,
                                 trailing: .paddingHorizontalButtonXSmall))
    }
    
    func listRow() -> some View {
        self
            .listRowBackground(Color.text.opacity(.opacityButtonBackground))
            .listRowSeparatorTint(Color.text.opacity(.opacityButtonBackground))
            .listRowInsets(.init(top: .paddingVerticalButtonXSmall,
                                 leading: .paddingHorizontalButtonXSmall,
                                 bottom: .paddingVerticalButtonXSmall,
                                 trailing: .paddingHorizontalButtonXSmall))
    }
    
    func listRowIcon() -> some View {
        self
            .font(.footnote.bold())
            .foregroundStyle(Color.text)
            .padding(.paddingCircleButtonMedium)
            .background {
                Circle()
                    .foregroundStyle(Color.text)
                    .opacity(.opacityButtonBackground)
            }
    }
    
    func listRowNoChrome() -> some View {
        self
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
    }
    
    func transactionPropertyRow() -> some View {
        self
            .listRowBackground(Color.text.opacity(.opacityButtonBackground))
            .listRowSeparatorTint(Color.text.opacity(.opacityButtonBackground))
    }
}
