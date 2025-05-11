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
        let finalCategory = try await getFinalCategory(
          manualCategory: manualCategory, receiptText: receiptText
        )

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

  func editExpense(
    _ expense: Expense, manualCategory: String? = nil, newMerchant: String, newAmount: Double
  ) async {
    await MainActor.run { isLoading = true }
    processingTask = Task {
      do {
        let receiptText = try await fetchReceiptText()
        let finalCategory = try await getFinalCategory(
          manualCategory: manualCategory, receiptText: receiptText
        )

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
    print("handlePhotoSelection called with item: \(item != nil ? "PhotosPickerItem" : "nil")")
    await MainActor.run { isLoading = true }

    processingTask = Task {
      do {
        // Handle both PhotosPicker and camera images
        var imageToProcess: UIImage?

        if let item = item {
          // Process PhotosPicker item
          print("Processing PhotosPicker item")
          guard let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
          else {
            throw NSError(domain: "Failed to load photo", code: -1, userInfo: nil)
          }
          imageToProcess = image
        } else if let cameraImage = selectedImage {
          // Process camera image
          print("Processing camera image: \(cameraImage.size)")
          imageToProcess = cameraImage
        } else {
          throw NSError(domain: "No image available", code: -1, userInfo: nil)
        }

        guard let image = imageToProcess else {
          throw NSError(domain: "Image processing failed", code: -1, userInfo: nil)
        }

        // Always process the image for OCR, regardless of source
        let processedImage = preprocessImageForOCR(image)
        let extractedText = try await ocrManager.extractText(from: processedImage)

        if extractedText.isEmpty {
          print("OCR returned empty text - using image anyway but no text extracted")
          // Still allow the user to manually enter info
          await MainActor.run {
            self.selectedImage = image
            isLoading = false
          }
          return
        }

        // Extract merchant and amount
        let extractedMerchant = extractMerchant(from: extractedText)
        let extractedAmount = extractAmount(from: extractedText)

        print("Extracted merchant: \(extractedMerchant)")
        print("Extracted amount: \(extractedAmount)")

        await MainActor.run {
          self.selectedImage = image
          self.merchant = extractedMerchant.isEmpty ? "" : extractedMerchant
          self.amount = extractedAmount
          self.amountText = extractedAmount > 0 ? String(format: "%.2f", extractedAmount) : ""
          isLoading = false
        }
      } catch {
        print("Photo processing error: \(error.localizedDescription)")
        await MainActor.run { isLoading = false }
      }
    }
  }

  // Improve image quality for OCR
  private func preprocessImageForOCR(_ image: UIImage) -> UIImage {
    // Resize large images to reasonable dimensions
    let maxDimension: CGFloat = 2048
    var processedImage = image

    if image.size.width > maxDimension || image.size.height > maxDimension {
      let scale = maxDimension / max(image.size.width, image.size.height)
      let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
      processedImage = image.resized(to: newSize) ?? image
    }

    return processedImage
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
    let validCategories = [
      "Dining", "Transportation", "Entertainment", "Groceries", "Electronics", "Other",
    ]

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
    let merchantKeywords = ["store", "market", "restaurant", "cafe", "shop", "inc", "llc"]
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
      if trimmed.isEmpty || trimmed.contains("total") || trimmed.contains("$")
        || trimmed.contains("tax") || trimmed.contains("cash") || trimmed.contains("card")
      {
        continue
      }
      if merchantKeywords.contains(where: trimmed.contains) || trimmed.count > 3 {
        // Clean special characters, keep alphanumeric and spaces
        let cleaned = line.trimmingCharacters(in: .whitespaces)
          .components(
            separatedBy: CharacterSet(charactersIn: ">,-!@#$%^&*()_+={}[]|\\:;\"'<>?,./~`")
          )
          .joined()
          .trimmingCharacters(in: .whitespaces)
          .capitalized
        print("Extracted merchant: \(cleaned) from line: \(line)")
        return cleaned
      }
    }
    print("No merchant found in text: \(text)")
    return ""
  }

  private func extractAmount(from text: String) -> Double {
    let lines = text.components(separatedBy: .newlines)

    // Look for common receipt patterns
    let totalPattern =
      "(?i)(?:total|balance|amount|sum)\\s*(?:due|:)?\\s*(?:CAD|USD)?\\s*[$]?\\s*(\\d+[.,]\\d{2})"
    let amountPattern = "[$]?\\s*(\\d+[.,]\\d{2})\\b"

    // Try finding a line with "total" or similar keywords first
    for line in lines {
      if line.range(of: "(?i)\\b(total|balance|due|amount|sum)\\b", options: .regularExpression)
        != nil
      {
        if let regex = try? NSRegularExpression(pattern: totalPattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.count))
        {
          let nsString = line as NSString
          let amountString = nsString.substring(with: match.range(at: 1))
            .replacingOccurrences(of: ",", with: ".")
          if let amount = Double(amountString) {
            print("Found total amount: \(amount) in line: \(line)")
            return amount
          }
        }
      }
    }

    // Collect all dollar amounts after finding any "total" keyword
    var foundTotalKeyword = false
    var potentialAmounts: [(amount: Double, index: Int)] = []

    for (index, line) in lines.enumerated() {
      let lowercaseLine = line.lowercased()

      // Look for total keyword
      if lowercaseLine.contains("total") || lowercaseLine.contains("balance")
        || lowercaseLine.contains("amount due")
      {
        foundTotalKeyword = true
        print("Found total indicator at line \(index): \(line)")

        // Check if this line itself has an amount
        if let regex = try? NSRegularExpression(pattern: amountPattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.count))
        {
          let nsString = line as NSString
          let amountString = nsString.substring(with: match.range(at: 1))
            .replacingOccurrences(of: ",", with: ".")
          if let amount = Double(amountString) {
            print("Found amount on total line: \(amount)")
            // High priority if amount is on same line as "total"
            return amount
          }
        }
      }

      // Collect all amounts, prioritizing those after a total keyword
      if let regex = try? NSRegularExpression(pattern: amountPattern),
         let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.count))
      {
        let nsString = line as NSString
        let amountString = nsString.substring(with: match.range(at: 1))
          .replacingOccurrences(of: ",", with: ".")
        if let amount = Double(amountString) {
          print("Found amount \(amount) at line \(index): \(line)")
          potentialAmounts.append((amount, index))
        }
      }
    }

    // If we found the total keyword, get the largest amount after it
    if foundTotalKeyword {
      let amountsAfterTotal = potentialAmounts.filter {
        $0.index > potentialAmounts.filter {
          lines[$0.index].lowercased().contains("total")
        }.map { $0.index }.max() ?? 0
      }

      if let largest = amountsAfterTotal.max(by: { $0.amount < $1.amount }) {
        print("Selected largest amount after total: \(largest.amount)")
        return largest.amount
      }
    }

    // If we couldn't find a total line, just use the largest amount in the receipt
    if let largest = potentialAmounts.max(by: { $0.amount < $1.amount }) {
      print("Using largest amount in receipt: \(largest.amount)")
      return largest.amount
    }

    print("No amount found in text")
    return 0
  }

  private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T)
    async throws -> T
  {
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
    Task {
      await MainActor.run {
        isLoading = false
        resetForm()
      }
    }
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

extension UIImage {
  func resized(to size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    defer { UIGraphicsEndImageContext() }
    draw(in: CGRect(origin: .zero, size: size))
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}

struct TimeoutError: Error {}
