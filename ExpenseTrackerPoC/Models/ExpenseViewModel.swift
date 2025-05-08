//
//  ExpenseViewModel.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation

class ExpenseViewModel: ObservableObject {
  @Published var merchant: String = ""
  @Published var category: String = ""
  @Published var isLoading: Bool = false
  @Published var expenses: [Expense] = []

  func categorizeExpense() async {
    guard !merchant.isEmpty else { return }
    await MainActor.run { isLoading = true }
    // Mock categorization (MLX in the next Step)
    try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate delay
    let mockCategory = "Dining" // Replace with MLX later
    let newExpense = Expense(
      id: Int64(expenses.count + 1), // Simple ID for in-memory
      merchant: merchant,
      category: mockCategory,
      timestamp: Date()
    )
    await MainActor.run {
      category = mockCategory
      expenses.append(newExpense)
      merchant = ""
      isLoading = false
    }
  }
}
