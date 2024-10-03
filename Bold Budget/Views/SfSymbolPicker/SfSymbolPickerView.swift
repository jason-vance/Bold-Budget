//
//  SfSymbolPickerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import SwiftUI

struct SfSymbolPickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var symbols: [String] = []
    @State private var searchText: String = ""
    @State private var searchPresented: Bool = false
    
    public var onSelected: (String) -> ()
    
    private var filteredSymbols: [String] {
        guard !searchText.isEmpty else { return symbols }
        let terms = searchText.split(separator: " ").map { String($0) }
        
        return symbols.filter { symbol in
            terms.allSatisfy { term in
                symbol.contains(term)
            }
        }
    }
    
    private func fetchSymbols() {
        Task {
            let sfSymbolsFileName = "sf_symbol_names"
            if let filepath = Bundle.main.path(forResource: sfSymbolsFileName, ofType: "txt") {
                do {
                    let contents = try String(contentsOfFile: filepath)
                    self.symbols = contents.split(separator: "\n").map { String($0) }
                } catch {
                    print("Contents could not be read. \(error.localizedDescription)")
                }
            } else {
                print("\(sfSymbolsFileName).txt could not be found")
            }
        }
    }
    
    private func select(symbol: String) {
        onSelected(symbol)
        dismiss()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            SearchArea()
                .padding(.padding)
            BarDivider()
            ScrollView {
                LazyVStack {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button {
                            select(symbol: symbol)
                        } label: {
                            SymbolRow(symbol)
                        }
                    }
                    if symbols.isEmpty {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.text)
                            .padding(.top, 100)
                    }
                }
                .padding()
            }
        }
        .background(Color.background)
        .onAppear { fetchSymbols() }
    }
    
    @ViewBuilder func SymbolRow(_ symbol: String) -> some View {
        HStack {
            Image(systemName: symbol)
                .buttonLabelMedium()
            Text(symbol)
                .foregroundStyle(Color.white)
            Spacer(minLength: 0)
        }
    }
    
    @ViewBuilder func TopBar() -> some View {
        ScreenTitleBar(
            "Pick a Symbol",
            leadingContent: { CloseButton() }
        )
    }
    
    @ViewBuilder func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            TitleBarButtonLabel(sfSymbol: "xmark")
        }
    }
    
    @ViewBuilder func SearchArea() -> some View {
        SearchBar(
            prompt: String(localized: "Search for a symbol"),
            searchText: $searchText,
            searchPresented: $searchPresented
        )
        .autocapitalization(.never)
    }
}

#Preview {
    SfSymbolPickerView() { _ in }
}
