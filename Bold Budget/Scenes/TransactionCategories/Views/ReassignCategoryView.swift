//
//  ReassignCategoryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 6/11/26.
//

import SwiftUI

/// Picks a replacement category for one being deleted, redesign palette: a title header with a
/// back button, an intro card explaining the move, and a card of candidate category rows. Self-
/// contained (own header + scroll) so it carries the redesign look without the shared List chrome,
/// mirroring `TransactionCategoryPickerView`.
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

    private var transactionsLabel: String {
        "\(affectedTransactionCount) transaction\(affectedTransactionCount == 1 ? "" : "s")"
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
            ScrollView {
                VStack(spacing: .padding) {
                    IntroCard()
                    if candidates.isEmpty {
                        EmptyState()
                    } else {
                        CandidatesCard()
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .confirmationDialog(
            "Move \(transactionsLabel) to '\(selectedReplacement?.name.value ?? "")' and delete '\(categoryToDelete.name.value)'?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move & Delete", role: .destructive) {
                confirmReassignAndDelete()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Reassign Transactions")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .padding(.horizontal, .barHeight)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("ReassignCategoryView.BackButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Intro

    @ViewBuilder private func IntroCard() -> some View {
        VStack(alignment: .leading, spacing: .paddingSmall) {
            Text("Pick a replacement category for \u{201C}\(categoryToDelete.name.value)\u{201D}.")
                .fontWeight(.semibold)
                .foregroundStyle(Color.appText)
            Text("\(transactionsLabel) will be moved to the category you pick.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: - Candidates

    @ViewBuilder private func CandidatesCard() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(candidates.enumerated()), id: \.element.id) { index, category in
                if index > 0 { RowDivider() }
                CandidateButton(category)
            }
        }
        .card(0)
    }

    @ViewBuilder private func CandidateButton(_ category: Transaction.Category) -> some View {
        Button {
            selectReplacement(category)
        } label: {
            CandidateRow(category)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func CandidateRow(_ category: Transaction.Category) -> some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: category.sfSymbol.value, size: 40, tint: .brandTeal)
            Text(category.name.value)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appText)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appMutedText)
        }
        .padding(.padding)
        .contentShape(Rectangle())
    }

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
            .padding(.leading, .padding)
    }

    // MARK: - Empty state

    @ViewBuilder private func EmptyState() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "exclamationmark.triangle", size: 56, tint: .brandTeal)
            Text("No Other Categories")
                .font(.title3.weight(.bold))
            Text("Create another category before deleting this one, so its transactions have somewhere to go.")
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
        ReassignCategoryView(
            budget: Budget(info: .sample),
            categoryToDelete: .sampleGroceries,
            affectedTransactionCount: 3,
            onCompleted: {}
        )
    }
}
