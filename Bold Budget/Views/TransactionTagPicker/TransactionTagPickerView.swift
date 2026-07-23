//
//  TransactionTagPickerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/10/24.
//

import Combine
import SwinjectAutoregistration
import SwiftUI

/// Picks a budget's transaction tags, redesign palette: a title header with a close button, a
/// rounded search field, and a card of tag rows. Self-contained (own header + scroll) so it carries
/// the redesign look without the shared nav-bar chrome, mirroring `TransactionCategoryPickerView`.
struct TransactionTagPickerView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject var budget: Budget
    @State private var searchText: String = ""

    public var onSelected: (Transaction.Tag) -> ()

    private var filteredTags: [Transaction.Tag] {
        let sortedTags = budget.transactionTags.sorted { $0.value < $1.value }

        guard !searchText.isEmpty else {
            return sortedTags
        }

        return sortedTags
            .filter { $0.value.localizedCaseInsensitiveContains(searchText) }
    }

    private func select(tag: Transaction.Tag) {
        onSelected(tag)
        dismiss()
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            SearchField()
            ScrollView {
                VStack(spacing: .padding) {
                    if budget.transactionTags.isEmpty {
                        EmptyState()
                    } else if filteredTags.isEmpty {
                        NoResults()
                    } else {
                        TagsCard()
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
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Pick a Tag")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .padding(.horizontal, .barHeight)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("TransactionTagPickerView.CloseButton")
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
                prompt: Text("Search for a tag").foregroundStyle(Color.appMutedText)
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .tint(Color.brandTeal)
            .foregroundStyle(Color.appText)
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

    // MARK: - Tags

    @ViewBuilder private func TagsCard() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredTags.enumerated()), id: \.element.id) { index, tag in
                if index > 0 { RowDivider() }
                TagButton(tag)
            }
        }
        .card(0)
    }

    @ViewBuilder private func TagButton(_ tag: Transaction.Tag) -> some View {
        Button {
            select(tag: tag)
        } label: {
            TagRow(tag)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func TagRow(_ tag: Transaction.Tag) -> some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: "tag", size: 40, tint: .brandTeal)
            Text(tag.value)
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

    // MARK: - Empty states

    @ViewBuilder private func EmptyState() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "tag", size: 56, tint: .brandTeal)
            Text("No Tags")
                .font(.title3.weight(.bold))
            Text("Any tags you add to your transactions will show up here.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .padding * 2)
    }

    @ViewBuilder private func NoResults() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "magnifyingglass", size: 56, tint: .brandTeal)
            Text("No Matches")
                .font(.title3.weight(.bold))
            Text("No tags match \u{201C}\(searchText)\u{201D}.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .padding * 2)
    }
}

#Preview("With Tags") {
    // `transactionTags` is derived from the budget's transactions, so seed a transaction that
    // carries the sample tags to populate the list.
    let budget = Budget(info: .sample)
    let tagged = Transaction(
        id: .init(),
        amount: Money(10)!,
        date: .now,
        categoryId: Transaction.Category.sampleGroceries.id,
        tags: Set(Transaction.Tag.samples + [.sample])
    )
    budget.transactions = [tagged.id: tagged]

    return NavigationStack {
        TransactionTagPickerView(budget: budget) { _ in }
    }
}

#Preview("Empty") {
    NavigationStack {
        TransactionTagPickerView(budget: Budget(info: .sample)) { _ in }
    }
}
