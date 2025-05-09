//
//  ExpenseViewModel.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation
import PhotosUI
import SQLite
import SwiftUI
import UIKit

class ExpenseViewModel: ObservableObject {
  @Published var merchant: String = ""
  @Published var category: String = ""
  @Published var amount: Double = 0
  @Published var amountText: String = ""
  @Published var isLoading: Bool = false
  @Published var isModelLoading: Bool = true
  @Published var expenses: [Expense] = []
  @Published var selectedPhoto: PhotosPickerItem?
  @Published var selectedImage: UIImage?
  @Published var errorMessage: String = ""
  @Published var showErrorAlert: Bool = false
  
  private let modelManager = ModelManager.shared
  private let ocrManager = OCRManager.shared
  private let databaseManager = DatabaseManager.shared
  private var processingTask: Task<Void, Never>?
  
  func loadModel() async {
    do {
      try await modelManager.loadModel()
      let savedExpenses = try databaseManager.loadExpenses()
      await MainActor.run {
        isModelLoading = false
        expenses = savedExpenses
      }
    } catch {
      print("Model load error: \(error)")
      await MainActor.run {
        errorMessage = "Failed to load model: \(error.localizedDescription)"
        showErrorAlert = true
        isModelLoading = false
      }
    }
  }
  
  private func getFinalCategory(manualCategory: String?, receiptText: String) async throws -> String {
    if let manualCategory = manualCategory {
      return manualCategory
    } else {
      return try await predictCategory(receiptText: receiptText)
    }
  }
  
  func categorizeExpense(manualCategory: String? = nil) async {
    guard !merchant.isEmpty else {
      await MainActor.run {
        errorMessage = "Please enter a merchant name"
        showErrorAlert = true
      }
      return
    }
    
    guard amount > 0 else {
      await MainActor.run {
        errorMessage = "Please enter a valid amount"
        showErrorAlert = true
      }
      return
    }
    
    await MainActor.run { isLoading = true }
    
    processingTask = Task {
      do {
        let receiptText = try await fetchReceiptText()
        let finalCategory = try await getFinalCategory(manualCategory: manualCategory, receiptText: receiptText)
        
        let newExpense = Expense(
          id: Int64(expenses.count + 1),
          merchant: merchant,
          category: finalCategory,
          amount: amount,
          timestamp: Date()
        )
        
        try databaseManager.saveExpense(newExpense)
        
        await MainActor.run {
          category = finalCategory
          expenses.append(newExpense)
          resetForm()
        }
      } catch {
        print("Categorization error: \(error)")
        await MainActor.run {
          errorMessage = "Failed to categorize: \(error.localizedDescription)"
          showErrorAlert = true
        }
      }
      await MainActor.run { isLoading = false }
    }
  }
  
  func editExpense(_ expense: Expense, manualCategory: String? = nil, newMerchant: String, newAmount: Double) async {
    await MainActor.run { isLoading = true }
    processingTask = Task {
      do {
        let receiptText = try await fetchReceiptText()
        let finalCategory = try await getFinalCategory(manualCategory: manualCategory, receiptText: receiptText)
        
        let updatedExpense = Expense(
          id: expense.id,
          merchant: newMerchant,
          category: finalCategory,
          amount: newAmount,
          timestamp: expense.timestamp
        )
        
        try databaseManager.updateExpense(updatedExpense)
        
        await MainActor.run {
          if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = updatedExpense
          }
          resetForm()
        }
      } catch {
        print("Edit expense error: \(error)")
        await MainActor.run {
          errorMessage = "Failed to edit expense: \(error.localizedDescription)"
          showErrorAlert = true
        }
      }
      await MainActor.run { isLoading = false }
    }
  }
  
  func handlePhotoSelection(_ item: PhotosPickerItem?) async {
    guard let item else {
      await MainActor.run { resetForm() }
      return
    }
    
    await MainActor.run { isLoading = true }
    
    processingTask = Task {
      do {
        let data = try await withTimeout(seconds: 10) {
          try await item.loadTransferable(type: Data.self)
        }
        guard let data, let uiImage = UIImage(data: data) else {
          throw NSError(domain: "Image conversion failed", code: -1)
        }
        let text = try await withTimeout(seconds: 10) {
          try await self.ocrManager.extractText(from: uiImage)
        }
        print("OCR extracted: \(text)")
        let merchant = extractMerchant(from: text)
        let amount = extractAmount(from: text)
        await MainActor.run {
          selectedImage = uiImage
          self.merchant = merchant
          self.amount = amount
          self.amountText = amount > 0 ? String(format: "%.2f", amount) : "" // Set TextField value
          isLoading = false
        }
      } catch {
        print("OCR error: \(error)")
        await MainActor.run {
          errorMessage = "Failed to process receipt: \(error.localizedDescription)"
          showErrorAlert = true
          isLoading = false
        }
      }
    }
  }
  
  func deleteExpense(at offsets: IndexSet) {
    Task {
      do {
        // Convert IndexSet to an Array to iterate manually
        for index in Array(offsets) {
          let expense = expenses[index]
          try databaseManager.deleteExpense(id: expense.id)
        }
        
        // Update the UI after all deletions are complete
        await MainActor.run {
          expenses.remove(atOffsets: offsets)
        }
      } catch {
        await MainActor.run {
          errorMessage = "Failed to delete expense: \(error.localizedDescription)"
          showErrorAlert = true
        }
      }
    }
  }
  
  func exportExpenses() throws -> URL {
    try databaseManager.exportToCSV()
  }
  
  func importExpenses(from url: URL) async throws {
    try databaseManager.importFromCSV(url: url)
    let updatedExpenses = try databaseManager.loadExpenses()
    await MainActor.run { expenses = updatedExpenses }
  }
  
  private func fetchReceiptText() async throws -> String {
    guard let image = selectedImage else { return merchant }
    return try await withTimeout(seconds: 10) {
      try await self.ocrManager.extractText(from: image)
    }
  }
  
  private func predictCategory(receiptText: String) async throws -> String {
    let validCategories = ["Dining", "Transportation", "Entertainment", "Groceries", "Electronics", "Other"]
    
    let prompt = """
    Categorize the purchase into one of: \(validCategories.joined(separator: ", ")). Return only the category name. For example, if the merchant is 'Walmart' and the receipt mentions 'TRAVEL ADAPT', return 'Electronics'. Use the receipt text for context.
    
    Merchant: \(merchant)
    Receipt: \(receiptText)
    """
    
    let result = try await withTimeout(seconds: 15) {
      try await self.modelManager.predict(input: self.merchant, prompt: prompt)
    }
    
    let trimmedResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
    
    return validCategories.contains(trimmedResult) ? trimmedResult : "Other"
  }
  
  private func extractMerchant(from text: String) -> String {
    let lines = text.components(separatedBy: .newlines)
    let storeNames = ["walmart", "starbucks", "target", "costco", "uber", "lyft"]
    for (index, line) in lines.prefix(5).enumerated() {
      let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
      if index == 0 && !trimmed.isEmpty && !trimmed.contains("$") && !trimmed.contains("@") {
        return line.trimmingCharacters(in: .whitespaces)
      }
      if storeNames.contains(where: trimmed.contains) {
        return line.trimmingCharacters(in: .whitespaces)
      }
    }
    return "Unknown"
  }
  
  private func extractAmount(from text: String) -> Double {
    let patterns = [
      "TOTAL\\s*\\$?(\\d+\\.\\d{2})", // TOTAL $19.19
      "SUBTOTAL\\s*\\$?(\\d+\\.\\d{2})", // SUBTOTAL $19.19
      "\\$(\\d+\\.\\d{2})" // $19.19
    ]
    for pattern in patterns {
      guard let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
            let range = Range(match.range(at: 1), in: text),
            let amount = Double(text[range]) else { continue }
      return amount
    }
    return 0
  }
  
  private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask { try await operation() }
      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        throw TimeoutError()
      }
      guard let result = try await group.next() else { throw TimeoutError() }
      group.cancelAll()
      return result
    }
  }
  
  func cancelProcessing() {
    processingTask?.cancel()
    Task { await MainActor.run { isLoading = false; resetForm() } }
  }
  
  private func resetForm() {
    merchant = ""
    category = ""
    amount = 0
    amountText = ""
    selectedPhoto = nil
    selectedImage = nil
  }
}

struct TimeoutError: Error {}
