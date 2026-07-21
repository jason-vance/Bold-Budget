//
//  ReassignCategoryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 6/11/26.
//

import SwiftUI

struct ReassignCategoryView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject var budget: Budget
    let categoryToDelete: Transaction.Category
    let affectedTransactionCount: Int
    let onCompleted: () -> Void

    @State private var selectedReplacement: Transaction.Category? = nil
    @State private var showConfirmation: Bool = false

    private var candidates: [Transaction.Category] {
        budget.transactionCategories.values
            .filter { $0.id != categoryToDelete.id }
            .sorted { $0.name.value < $1.name.value }
    }

    private func selectReplacement(_ category: Transaction.Category) {
        selectedReplacement = category
        showConfirmation = true
    }

    private func confirmReassignAndDelete() {
        guard let replacement = selectedReplacement else { return }
        budget.remove(transactionCategory: categoryToDelete, replacingWith: replacement)
        onCompleted()
        dismiss()
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            BarDivider()
            if candidates.isEmpty {
                NoCandidatesView()
            } else {
                List {
                    ForEach(candidates) { category in
                        Button {
                            selectReplacement(category)
                        } label: {
                            CategoryRow(category)
                        }
                        .listRowNoChrome()
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Reassign Transactions")
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background)
        .confirmationDialog(
            "Move \(affectedTransactionCount) transaction\(affectedTransactionCount == 1 ? "" : "s") to '\(selectedReplacement?.name.value ?? "")' and delete '\(categoryToDelete.name.value)'?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move & Delete", role: .destructive) {
                confirmReassignAndDelete()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    @ViewBuilder private func Header() -> some View {
        VStack(alignment: .leading, spacing: .paddingSmall) {
            Text("Pick a replacement category for '\(categoryToDelete.name.value)'.")
                .foregroundStyle(Color.text)
            Text("\(affectedTransactionCount) transaction\(affectedTransactionCount == 1 ? "" : "s") will be moved to the category you pick.")
                .font(.caption)
                .foregroundStyle(Color.text.opacity(.opacityMutedText))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    @ViewBuilder private func NoCandidatesView() -> some View {
        ContentUnavailableView(
            "No Other Categories",
            systemImage: "exclamationmark.triangle",
            description: Text("Create another category before deleting this one, so its transactions have somewhere to go.")
        )
    }

    @ViewBuilder private func CategoryRow(_ category: Transaction.Category) -> some View {
        HStack {
            Image(systemName: category.sfSymbol.value)
            Text(category.name.value)
                .buttonLabelSmall()
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .opacity(.opacityMutedText)
        }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReassignCategoryView(
            budget: Budget(info: .sample),
            categoryToDelete: .sampleGroceries,
            affectedTransactionCount: 3,
            onCompleted: {}
        )
    }
}
