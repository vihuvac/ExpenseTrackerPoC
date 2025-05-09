//
//  ExpenseListView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import SwiftUI

struct ExpenseListView: View {
  let expenses: [Expense]
  var onDelete: ((IndexSet) -> Void)?

  @State private var showDeleteConfirmation = false
  @State private var deleteOffsets: IndexSet?

  var body: some View {
    List {
      if expenses.isEmpty {
        Text("No expenses yet")
          .foregroundColor(.gray)
          .frame(maxWidth: .infinity, alignment: .center)
          .accessibilityLabel("No expenses")
      }
      
      ForEach(expenses) { expense in
        VStack(alignment: .leading, spacing: 8) {
          Text("Merchant: \(expense.merchant)")
            .font(.headline)
          Text("Category: \(expense.category)")
          Text("Amount: $\(String(format: "%.2f", expense.amount))")
          Text("Date: \(expense.timestamp, style: .date)")
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Expense: \(expense.merchant), \(expense.category), $\(String(format: "%.2f", expense.amount))")
      }
      .onDelete { offsets in
        deleteOffsets = offsets
        showDeleteConfirmation = true
      }
    }
    .alert("Delete Expense", isPresented: $showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let offsets = deleteOffsets {
          withAnimation(.easeInOut) {
            onDelete?(offsets)
          }
        }
      }
    } message: {
      Text("Are you sure you want to delete this expense?")
    }
  }
}

#Preview {
  ExpenseListView(
    expenses: [
      Expense(id: 1, merchant: "Starbucks", category: "Dining", amount: 20.50, timestamp: Date()),
      Expense(id: 2, merchant: "Walmart", category: "Electronics", amount: 16.98, timestamp: Date())
    ]
  )
}
