//
//  SfSymbolPickerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import SwiftUI

/// Picks an SF Symbol, redesign palette: a title header with a close button, a rounded search
/// field, and a grid of symbol tiles. With an empty search it shows a large grid of curated
/// suggestions; typing searches the full SF Symbol catalog like before. Self-contained (own header
/// + scroll) so it carries the redesign look, mirroring `TransactionCategoryPickerView`.
struct SfSymbolPickerView: View {

    /// A small, budget-flavored set of symbols shown before the user searches.
    private static let suggestedSymbols: [String] = [
        "house.fill", "cart.fill", "fork.knife", "takeoutbag.and.cup.and.straw.fill",
        "cup.and.saucer.fill", "wineglass.fill", "car.fill", "fuelpump.fill",
        "bus", "tram.fill", "airplane", "creditcard.fill",
        "banknote.fill", "dollarsign.circle.fill", "wallet.pass.fill", "chart.pie.fill",
        "cross.case.fill", "pills.fill", "heart.fill", "dumbbell.fill",
        "gift.fill", "bag.fill", "tshirt.fill", "scissors",
        "gamecontroller.fill", "tv.fill", "book.fill", "graduationcap.fill",
        "pawprint.fill", "wifi", "bolt.fill", "drop.fill",
        "flame.fill", "wrench.and.screwdriver.fill", "phone.fill", "envelope.fill",
        "briefcase.fill", "building.2.fill", "gearshape.fill", "star.fill"
    ]

    @Environment(\.dismiss) private var dismiss

    @Binding public var selectedSymbol: String?

    @State private var symbols: [String] = []
    @State private var searchText: String = ""

    private var isSearching: Bool { !searchText.isEmpty }

    private var filteredSymbols: [String] {
        guard isSearching else { return Self.suggestedSymbols }
        let terms = searchText.lowercased().split(separator: " ").map { String($0) }

        return symbols.filter { symbol in
            terms.allSatisfy { term in
                symbol.contains(term)
            }
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 64), spacing: .paddingSmall)]
    }

    private func fetchSymbols() {
        Task {
            let sfSymbolsFileName = "sf_symbol_names"
            if let filepath = Bundle.main.path(forResource: sfSymbolsFileName, ofType: "txt") {
                do {
                    let contents = try String(contentsOfFile: filepath, encoding: .utf8)
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
        selectedSymbol = symbol
        dismiss()
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            SearchField()
            ScrollView {
                VStack(spacing: .padding) {
                    if isSearching && symbols.isEmpty {
                        Loading()
                    } else if isSearching && filteredSymbols.isEmpty {
                        NoResults()
                    } else {
                        SectionHeader(isSearching ? "Results" : "Suggested")
                        SymbolGrid()
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .animation(.snappy, value: isSearching)
        .onAppear { fetchSymbols() }
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Pick a Symbol")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .padding(.horizontal, .barHeight)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("SfSymbolPickerView.CloseButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Search

    @ViewBuilder private func SearchField() -> some View {
        HStack(spacing: .paddingSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.appMutedText)
            TextField(
                "Search",
                text: $searchText,
                prompt: Text("Search for a symbol").foregroundStyle(Color.appMutedText)
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .tint(Color.brandTeal)
            .foregroundStyle(Color.appText)
            .accessibilityIdentifier("SfSymbolPickerView.SearchArea")
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.appMutedText)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                .foregroundStyle(Color.appSurface)
        }
        .padding(.horizontal)
        .padding(.bottom, .paddingSmall)
    }

    // MARK: - Grid

    @ViewBuilder private func SectionHeader(_ title: LocalizedStringKey) -> some View {
        HStack {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(Color.appMutedText)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private func SymbolGrid() -> some View {
        LazyVGrid(columns: columns, spacing: .paddingSmall) {
            ForEach(filteredSymbols, id: \.self) { symbol in
                Button {
                    select(symbol: symbol)
                } label: {
                    SymbolTile(symbol)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder private func SymbolTile(_ symbol: String) -> some View {
        let isSelected = selectedSymbol == symbol
        Image(systemName: symbol)
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(isSelected ? Color.white : Color.appText)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(isSelected ? Color.brandTeal : Color.appSurface)
            }
    }

    // MARK: - States

    @ViewBuilder private func Loading() -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(Color.appText)
            .frame(maxWidth: .infinity)
            .padding(.top, 100)
    }

    @ViewBuilder private func NoResults() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "magnifyingglass", size: 56, tint: .brandTeal)
            Text("No Matches")
                .font(.title3.weight(.bold))
            Text("No symbols match \u{201C}\(searchText)\u{201D}.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .padding * 2)
    }
}

#Preview {
    NavigationStack {
        SfSymbolPickerView(selectedSymbol: .constant("cart.fill"))
    }
}
