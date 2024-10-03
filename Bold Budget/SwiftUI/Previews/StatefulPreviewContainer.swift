//
//  StatefulPreviewContainer.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import SwiftUI

struct StatefulPreviewContainer<Value, Content: View>: View {
    
    @State var value: Value
    var content: (Binding<Value>) -> Content
    
    var body: some View {
        content($value)
    }
    
    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }
}

struct FocusStatefulPreviewContainer<Content: View>: View {
    
    @FocusState var value: Bool
    var content: (FocusState<Bool>.Binding) -> Content
    
    var body: some View {
        content($value)
    }
    
    init(_ value: Bool, content: @escaping (FocusState<Bool>.Binding) -> Content) {
        self._value.wrappedValue = value
        self.content = content
    }
}
