//
//  TitleBarButtonLabel.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import SwiftUI

struct TitleBarButtonLabel: View {
    
    let sfSymbol: String
    @State private var image: String = ""
    
    var body: some View {
        Image(systemName: sfSymbol)
            .font(.subheadline.bold())
            .foregroundStyle(Color.text)
            .aspectRatio(contentMode: .fit)
            .frame(width: 18, height: 18)
            .contentTransition(.symbolEffect(.replace))
        .onChange(of: sfSymbol, initial: true) { oldSfSymbol, newSfSymbol in
            withAnimation(.snappy) {
                self.image = newSfSymbol
            }
        }
    }
}

#Preview {
    TitleBarButtonLabel(sfSymbol: "circle")
        .background(Color.background)
}
