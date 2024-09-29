//
//  ContentView.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/27/24.
//

import SwiftUI
import SwinjectAutoregistration

struct ContentView: View {
    
    let stringProvider = iocContainer~>StringProvider.self
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
            Text(stringProvider.string)
        }
        .padding()
        .foregroundStyle(Color.text)
        .background(Color.background)
    }
}

#Preview {
    ContentView()
}
