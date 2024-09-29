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
        DashboardView()
    }
}

#Preview {
    ContentView()
}
