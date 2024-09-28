//
//  ContentView.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/27/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
            Text("Hello, world!")
        }
        .padding()
        .foregroundStyle(Color.text)
        .background(Color.background)
    }
}

#Preview {
    ContentView()
}
