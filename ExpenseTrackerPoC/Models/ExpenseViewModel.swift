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
  
  func categorizeExpense() async {
    guard !merchant.isEmpty else {
      await MainActor.run {
        errorMessage = "Please enter a merchant name"
        showErrorAlert = true
      }
      return
    }
    
    await MainActor.run { isLoading = true }
    
    do {
      let prompt = """
      Analyze this merchant and categorize it into one of these exact categories:
      - Dining (for restaurants, cafes)
      - Transportation (for taxis, fuel)
      - Entertainment (for movies, events)
      - Groceries (for supermarkets, food)
      - Electronics (for tech items)
      - Other (anything else)
      
      Return only the exact category name, nothing else.
      Merchant: \(merchant)
      """
      
      let result = try await withTimeout(seconds: 15) {
        try await self.modelManager.predict(input: self.merchant, prompt: prompt)
      }
      
      let newExpense = Expense(
        id: Int64(expenses.count + 1),
        merchant: merchant,
        category: result,
        amount: amount,
        timestamp: Date()
      )
      
      try databaseManager.saveExpense(newExpense)
      
      await MainActor.run {
        category = result
        expenses.append(newExpense)
        merchant = ""
        amount = 0
        selectedPhoto = nil
        selectedImage = nil
        isLoading = false
      }
    } catch {
      print("Categorization error: \(error)")
      await MainActor.run {
        errorMessage = "Failed to categorize expense: \(error.localizedDescription)"
        showErrorAlert = true
        isLoading = false
      }
    }
  }
  
  func handlePhotoSelection(_ item: PhotosPickerItem?) async {
    guard let item = item else {
      await MainActor.run { merchant = "" }
      return
    }
    
    await MainActor.run { isLoading = true }
    
    do {
      let data = try await withTimeout(seconds: 10) {
        try await item.loadTransferable(type: Data.self)
      }
      
      guard let data = data, let uiImage = UIImage(data: data) else {
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
  
  private func extractMerchant(from text: String) -> String {
    let lines = text.components(separatedBy: .newlines)
    
    // Prioritize lines that look like merchant names
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.count > 2 && trimmed.count < 50 && !trimmed.contains("$") && !trimmed.contains("@") {
        return trimmed
      }
    }
    
    // Fallback to first non-empty line
    return lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
  }
  
  private func extractAmount(from text: String) -> Double {
    let pattern = "\\b\\d+\\.\\d{2}\\b"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
    
    let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
    let amounts = matches.compactMap { result -> Double? in
      let substring = (text as NSString).substring(with: result.range)
      return Double(substring)
    }
    
    // Return the largest amount found (likely the total)
    return amounts.max() ?? 0
  }
  
  private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask { try await operation() }
      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        throw TimeoutError()
      }
      guard let result = try await group.next() else {
        throw TimeoutError()
      }
      group.cancelAll()
      return result
    }
  }
  
  func cancelProcessing() {
    isLoading = false
    // TODO: Add any other cancellation logic, for example:
    // - Cancel ongoing network requests
    // - Reset form fields
    // - Clear any processing state
  }
  
  func deleteExpense(at offsets: IndexSet) {
    Task {
      await MainActor.run {
        do {
          try offsets.forEach { index in
            let expense = expenses[index]
            try databaseManager.deleteExpense(id: expense.id)
            expenses.remove(at: index)
          }
        } catch {
          errorMessage = "Failed to delete expense: \(error.localizedDescription)"
          showErrorAlert = true
        }
      }
    }
  }
}

// Define helper methods to convert between Expense and database rows.
extension Expense {
  // Convert to a dictionary for insertion
  func asDictionary() -> [String: Any] {
    return [
      "id": id,
      "merchant": merchant,
      "category": category,
      "amount": amount,
      "timestamp": timestamp.timeIntervalSince1970
    ]
  }
  
  // Create from a SQLite.Row
  static func fromRow(_ row: Row) -> Expense {
    return Expense(
      id: row[Expression<Int64>("id")],
      merchant: row[Expression<String>("merchant")],
      category: row[Expression<String>("category")],
      amount: row[Expression<Double>("amount")],
      timestamp: Date(timeIntervalSince1970: row[Expression<Double>("timestamp")])
    )
  }
}

struct TimeoutError: Error {}
