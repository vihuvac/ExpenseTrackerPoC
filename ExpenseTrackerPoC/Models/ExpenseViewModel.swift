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
  @Published var isModelLoading: Bool = true
  @Published var expenses: [Expense] = []

  func loadModel() async {
    do {
      try await ModelManager.shared.loadModel()
      await MainActor.run {
        isModelLoading = false
        expenses = []
      }
    } catch {
      print("Model load error: \(error)")
      await MainActor.run {
        category = "Model Error"
        isModelLoading = false
      }
    }
  }

  func categorizeExpense() async {
    guard !merchant.isEmpty else { return }
    await MainActor.run { isLoading = true }
    do {
      let result = try await ModelManager.shared.predict(
        input: "Classify the expense: \(merchant)",
        prompt: "Return the category (e.g., Groceries, Dining, Entertainment)."
      )
      let newExpense = Expense(
        id: Int64(expenses.count + 1),
        merchant: merchant,
        category: result,
        timestamp: Date()
      )
      await MainActor.run {
        category = result
        expenses.append(newExpense)
        merchant = ""
        isLoading = false
      }
    } catch {
      print("Error: \(error)")
      await MainActor.run {
        category = "Error"
        isLoading = false
      }
    }
  }
}
