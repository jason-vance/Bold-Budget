//
//  SearchBar.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import SwiftUI

struct SearchBar: View {
    
    @State var prompt: String
    @Binding var searchText: String
    @Binding var searchPresented: Bool
    var action: ()->()
    @FocusState private var focus
    
    @State private var showCancel: Bool = false
    
    var body: some View {
        HStack {
            TextField(
                prompt,
                text: $searchText,
                prompt: Text(prompt).foregroundStyle(Color.text.opacity(.opacityButtonBackground))
            )
            .submitLabel(.search)
            .onSubmit(of: .text) {
                action()
            }
            .tint(Color.text)
            .foregroundColor(Color.text)
            .focused($focus)
            .textFieldStyle(.plain)
            .overlay(alignment: .trailing) {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.text.opacity(.opacityButtonBackground))
                }
                .opacity(showCancel ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.text.opacity(.opacityButtonBackground))
            }
            if showCancel {
                Button(action: {
                    searchText = ""
                    focus = false
                }) {
                    Text("Cancel")
                        .foregroundColor(Color.text)
                }
                .transition(.asymmetric(
                    insertion: .push(from: .trailing),
                    removal: .push(from: .leading)
                ))
            }
        }
        .onChange(of: focus, initial: true) { oldFocus, newFocus in
            searchPresented = newFocus
            withAnimation(.snappy) {
                showCancel = newFocus
            }
        }
    }
}

#Preview {
    StatefulPreviewContainer("") { searchText in
        StatefulPreviewContainer(false) { searchedPresented in
            VStack {
                SearchBar(
                    prompt: "Search prompt",
                    searchText: searchText,
                    searchPresented: searchedPresented,
                    action: { }
                )
                Text("searchedPresented: \(searchedPresented.wrappedValue)")
                Spacer()
            }
        }
    }
    .background(Color.background)
}
