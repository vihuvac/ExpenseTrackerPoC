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

  var body: some View {
    List {
      ForEach(expenses) { expense in
        VStack(alignment: .leading) {
          Text("Merchant: \(expense.merchant)")
            .font(.headline)
          Text("Category: \(expense.category)")
          Text("Date: \(expense.timestamp, style: .date)")
            .font(.caption)
        }
      }
      .onDelete(perform: onDelete)
    }
  }
}

#Preview {
  ExpenseListView(
    expenses: [
      Expense(id: 1, merchant: "Starbucks", category: "Dining", amount: 20.50, timestamp: Date()),
      Expense(id: 2, merchant: "Walmart", category: "Groceries", amount: 16.00, timestamp: Date())
    ]
  )
}
