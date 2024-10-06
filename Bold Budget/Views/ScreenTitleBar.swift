//
//  ScreenTitleBar.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import SwiftUI

struct ScreenTitleBar<PrimaryContent:View,LeadingContent:View,TrailingContent:View>: View {
    
    let primaryContent: () -> PrimaryContent
    let leadingContent: (() -> LeadingContent)?
    let trailingContent: (() -> TrailingContent)?

    init(
        _ text: String
    ) where PrimaryContent == Text, LeadingContent == Text, TrailingContent == Text {
        self.primaryContent = { Text(text) }
        self.leadingContent = nil
        self.trailingContent = nil
    }
    
    init(
        _ text: String,
        leadingContent: @escaping () -> LeadingContent
    ) where PrimaryContent == Text, TrailingContent == Text {
        self.primaryContent = { Text(text) }
        self.leadingContent = leadingContent
        self.trailingContent = nil
    }
    
    init(
        _ text: String,
        trailingContent: @escaping () -> TrailingContent
    ) where PrimaryContent == Text, LeadingContent == Text {
        self.primaryContent = { Text(text) }
        self.leadingContent = nil
        self.trailingContent = trailingContent
    }
    
    init(
        primaryContent: @escaping () -> PrimaryContent,
        leadingContent: @escaping () -> LeadingContent,
        trailingContent: @escaping () -> TrailingContent
    ) {
        self.primaryContent = primaryContent
        self.leadingContent = leadingContent
        self.trailingContent = trailingContent
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let leadingContent = leadingContent {
                leadingContent()
            }
            Spacer(minLength: 0)
            TitleText()
            Spacer(minLength: 0)
            if let trailingContent = trailingContent {
                trailingContent()
            }
        }
        .frame(height: .barHeight)
        .overlay(alignment: .bottom) { BarDivider() }
    }
    
    @ViewBuilder func TitleText() -> some View {
        primaryContent()
            .font(.subheadline.bold())
            .foregroundStyle(Color.text)
    }
}

#Preview("Title Only") {
    ScreenTitleBar("Screen Title Bar")
}

#Preview("LeadingContent") {
    ScreenTitleBar("Screen Title Bar", leadingContent: {
        Button {
            
        } label: {
            Image(systemName: "chevron.backward")
                .font(.subheadline.bold())
                .foregroundStyle(Color.text)
        }
    })
}

#Preview("TrailingContent") {
    ScreenTitleBar("Screen Title Bar", trailingContent: {
        Button {
            
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.bold())
                .foregroundStyle(Color.text)
        }
    })
}

#Preview("ComplexContent") {
    ScreenTitleBar {
        Menu {
            Text("Posts")
            Text("Article")
            Text("Recipe")
        } label: {
            HStack {
                Text("Post")
                TitleBarButtonLabel(sfSymbol: "chevron.down")
            }
        }
    } leadingContent: {
        Button {
            
        } label: {
            TitleBarButtonLabel(sfSymbol: "xmark")
        }
    } trailingContent: {
        HStack {
            Button {
                
            } label: {
                TitleBarButtonLabel(sfSymbol: "circle")
            }
            Button {
                
            } label: {
                TitleBarButtonLabel(sfSymbol: "heart")
            }
        }
    }
}
