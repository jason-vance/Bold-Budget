//
//  PreviewContainerWithSetup.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import SwiftUI

struct PreviewContainerWithSetup<Content: View>: View {
    
    var content: () -> Content
    
    var body: some View {
        content()
    }
    
    init(
        setup: @escaping () -> Void,
        content: @escaping () -> Content) {
            
        setup()
        self.content = content
    }
}
