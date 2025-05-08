//
//  ExpenseListView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import SwiftUI

struct ExpenseListView: View {
  let expenses: [Expense]

  var body: some View {
    List(expenses) { expense in
      VStack(alignment: .leading) {
        Text("Merchant: \(expense.merchant)")
          .font(.headline)
        Text("Category: \(expense.category)")
        Text("Date: \(expense.timestamp, style: .date)")
          .font(.caption)
      }
    }
  }
}

#Preview {
  ExpenseListView(
    expenses: [
      Expense(id: 1, merchant: "Starbucks", category: "Dining", timestamp: Date()),
      Expense(id: 2, merchant: "Walmart", category: "Groceries", timestamp: Date())
    ]
  )
}
