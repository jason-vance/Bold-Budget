//
//  EnvelopesView.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/13/26.
//

import SwiftUI

struct EnvelopesView: View {
    
    struct Category: Identifiable {
        var id: Transaction.Category.Id { category.id }
        let category: Transaction.Category
        let transactions: [Transaction]

        /// Categories are no longer income/expense-typed, so an envelope is treated as income
        /// only when every transaction in it is income.
        var isIncome: Bool {
            !transactions.isEmpty && transactions.allSatisfy { $0.kind == .income }
        }
    }
    
    @StateObject var budget: Budget
    let timeFrame: TimeFrame
    
    @State private var expandedCategories: Set<Transaction.Category> = []
    
    var displayCategories: [Category] {
        budget.transactionsByCategory
            .map(Category.init)
            .sorted { $0.category.name.value < $1.category.name.value }
            .sorted { $0.category.goal != nil && $1.category.goal == nil }
            .sorted { $0.isIncome && !$1.isIncome }
    }
    
    var body: some View {
        ForEach(displayCategories) { category in
            CategorySection(category)
        }
    }
    
    @ViewBuilder private func CategorySection(_ category: Category) -> some View {
        let transactions = category.transactions
            .filter {
                $0.date >= timeFrame.start &&
                $0.date <= timeFrame.end
            }
            .sorted { $0.date > $1.date }
        let totalAmount = transactions.reduce(Money.zero) { $0 + $1.amount }
        
        Section {
            CategoryHeader(
                category: category.category,
                isIncome: category.isIncome,
                totalAmount: totalAmount,
                transactionCount: transactions.count
            )
            .listRow()
            if expandedCategories.contains(category.category) {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction)
                }
            }
        }
    }
    
    @ViewBuilder private func CategoryHeader(category: Transaction.Category, isIncome: Bool, totalAmount: Money, transactionCount: Int) -> some View {
        Button {
            withAnimation(.snappy) {
                if expandedCategories.contains(category) {
                    expandedCategories.remove(category)
                } else {
                    expandedCategories.insert(category)
                }
            }
        } label: {
            VStack(spacing: 8) {
                VStack {
                    HStack(alignment: .lastTextBaseline) {
                        Image(systemName: category.sfSymbol.value)
                            .font(.headline)
                        Text(category.name.value)
                            .font(.headline)
                    }
                    HStack {
                        Text("\(isIncome ? "+" : "")\(totalAmount.formatted())")
                            .font(.title3.bold())
                    }
                    if let goal = category.goal {
                        HStack {
                            if goal.period != timeFrame.period {
                                let avgPerPeriod = totalAmount / goal.period.number(in: timeFrame.period)
                                Text("Average: \(avgPerPeriod.formatted())/\(goal.period.toUiString())")
                                Spacer()
                            }
                            Text("Goal: \(goal.comparison == .lessThan ? "<" : ">") \(goal.amount.formatted())/\(goal.period.toUiString())")
                        }
                        .font(.caption2.bold())
                        .opacity(0.5)
                    }
                }

                if let goal = category.goal {
                    let multiplier = goal.period.number(in: timeFrame.period)
                    let goalAmount = goal.amount * multiplier
                    let percent = totalAmount.amount / goalAmount.amount

                    if percent >= 1 {
                        RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                            .foregroundStyle(Color.text)
                            .frame(height: 8)
                    } else {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                                .stroke(style: .init(lineWidth: 1))
                                .foregroundStyle(Color.text)
                                .frame(height: 8)
                            Rectangle()
                                .foregroundStyle(Color.text.opacity(0.35))
                                .frame(height: 8)
                                .containerRelativeFrame(.horizontal) { length, axis in
                                    length * percent
                                }
                                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous))
                        }
                    }
                }

                HStack {
                    if let goal = category.goal {
                        let multiplier = goal.period.number(in: timeFrame.period)
                        let goalAmount = goal.amount * multiplier

                        // For a "less than" goal, going over is the problem to flag; for a
                        // "greater than" goal, falling short is.
                        if goal.comparison == .lessThan {
                            if let overAmount = totalAmount - goalAmount {
                                Text("\(overAmount.formatted()) over goal!")
                                    .bold()
                                    .buttonLabelXSmall(isProminent: true)
                            } else if let underAmount = goalAmount - totalAmount {
                                Text("\(underAmount.formatted()) left")
                                    .bold()
                            }
                        } else {
                            if let overAmount = totalAmount - goalAmount {
                                Text("\(overAmount.formatted()) over goal!")
                                    .bold()
                            } else if let underAmount = goalAmount - totalAmount {
                                Text("\(underAmount.formatted()) to go")
                                    .bold()
                                    .buttonLabelXSmall(isProminent: true)
                            }
                        }
                    }
                    Spacer()
                    Text("\(transactionCount) \(transactionCount == 1 ? "transaction" : "transactions")")
                    if transactionCount > 0 {
                        Text(expandedCategories.contains(category) ? "Hide" : "Show")
                            .buttonLabelXSmall()
                    }
                }
                .font(.caption2)
            }
            .contentTransition(.numericText())
        }
    }
    
    @ViewBuilder private func TransactionRow(_ transaction: Transaction) -> some View {
        NavigationLink {
            TransactionDetailView(
                budget: budget,
                transaction: transaction
            )
        } label: {
            TransactionRowView(
                budget: budget,
                transaction: transaction,
                category: budget.getCategoryBy(id: transaction.categoryId)
            )
        }
        .listRow()
    }
}

#Preview {
    List {
        EnvelopesView(
            budget: Budget(info: .sample),
            timeFrame: .init(period: .year, containing: .now)
        )
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .foregroundStyle(Color.text)
    .background(Color.background)
}
