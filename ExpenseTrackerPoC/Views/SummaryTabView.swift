//
//  SummaryTabView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-11.
//

import SwiftUI

struct SummaryTabView: View {
  @ObservedObject var viewModel: ExpenseViewModel

  var body: some View {
    SummaryView(expenses: viewModel.expenses)
      .navigationTitle("Summary")
  }
}

#Preview {
  let previewViewModel = ExpenseViewModel(isPreviewMode: true)
  previewViewModel.expenses = [
    Expense(
      id: 1,
      merchant: "Starbucks",
      category: "Dining",
      amount: 20.50,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: 2,
      merchant: "Walmart",
      category: "Electronics",
      amount: 16.98,
      receiptImageURL: nil,
      timestamp: Date()
    ),
  ]

  return NavigationView {
    SummaryTabView(viewModel: previewViewModel)
  }
}
