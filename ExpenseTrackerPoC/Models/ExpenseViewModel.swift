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
  @Published var isReceiptProcessing: Bool = false
  @Published var isModelLoading: Bool = true
  @Published var expenses: [Expense] = []
  @Published var selectedPhoto: PhotosPickerItem?
  @Published var selectedImage: UIImage?
  @Published var temporaryReceiptURL: URL?
  @Published var errorMessage: String = ""
  @Published var showErrorAlert: Bool = false
  @Published var skeletonId: Int64 = 0

  // Flag to determine if we're in preview mode
  private var isPreviewMode: Bool

  private let modelManager: ModelManager
  private let ocrManager: OCRManager
  private let databaseManager: DatabaseManager
  private var processingTask: Task<Void, Never>?

  init(isPreviewMode: Bool = false) {
    self.isPreviewMode = isPreviewMode

    if isPreviewMode {
      // Use dummy managers for preview
      self.modelManager = ModelManager.shared
      self.ocrManager = OCRManager.shared
      self.databaseManager = DatabaseManager.shared
      // Skip loading in preview mode
      self.isModelLoading = false
    } else {
      // Use real managers for actual app
      self.modelManager = ModelManager.shared
      self.ocrManager = OCRManager.shared
      self.databaseManager = DatabaseManager.shared
    }
  }

  func loadModel() async {
    // Skip actual loading if in preview mode
    if isPreviewMode {
      await MainActor.run {
        isModelLoading = false
        // You could set some sample expenses here
      }
      return
    }

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

    // Create a unique ID for this expense that will be used for both skeleton and expense
    let newExpenseId = Int64(Date().timeIntervalSince1970 * 1000)

    await MainActor.run {
      skeletonId = newExpenseId // Set the skeleton ID to match the new expense
      isLoading = true
      isReceiptProcessing = true // Set this to true to show the skeleton loader
    }

    processingTask = Task {
      do {
        let receiptText = try await fetchReceiptText()
        let finalCategory = try await getFinalCategory(
          manualCategory: manualCategory, receiptText: receiptText
        )

        let newExpense = Expense(
          id: newExpenseId,
          merchant: merchant,
          category: finalCategory,
          amount: amount,
          receiptImageURL: temporaryReceiptURL,
          timestamp: Date()
        )

        try databaseManager.saveExpense(newExpense)

        // First add the expense to the list
        await MainActor.run {
          category = finalCategory

          // Insert at the beginning instead of appending to the end
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            expenses.insert(newExpense, at: 0)
          }

          // Keep skeleton visible a bit longer to ensure smooth transition
          Task {
            // Wait for the expense to be visible and rendered
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms

            // Then hide the skeleton with animation
            withAnimation(.easeOut(duration: 0.3)) {
              isReceiptProcessing = false
            }
            resetForm()
          }
        }
      } catch {
        print("Categorization error: \(error)")
        await MainActor.run {
          errorMessage = "Failed to categorize: \(error.localizedDescription)"
          showErrorAlert = true
        }
      }
      await MainActor.run {
        isLoading = false
        // isReceiptProcessing is already set to false in the success handler
      }
    }
  }

  func editExpense(
    _ expense: Expense, manualCategory: String? = nil, newMerchant: String, newAmount: Double
  ) async {
    await MainActor.run {
      skeletonId = expense.id // Use the existing expense ID for the skeleton
      isLoading = true
      isReceiptProcessing = true // Set this to true to show the skeleton loader
    }
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
          receiptImageURL: expense.receiptImageURL,
          timestamp: expense.timestamp
        )

        try databaseManager.updateExpense(updatedExpense)

        // First update the expense list
        await MainActor.run {
          if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              expenses[index] = updatedExpense
            }
          }
        }

        // Small delay to ensure the expense update is visible
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then hide the skeleton
        await MainActor.run {
          withAnimation(.easeOut(duration: 0.2)) {
            isReceiptProcessing = false
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
      await MainActor.run {
        isLoading = false
        // isReceiptProcessing is already set to false in the success handler
      }
    }
  }

  func handlePhotoSelection(_ item: PhotosPickerItem?) async {
    print("handlePhotoSelection called with item: \(item != nil ? "PhotosPickerItem" : "nil")")
    // Generate a unique ID for this processing session
    let processingId = Int64(Date().timeIntervalSince1970 * 1000)

    await MainActor.run {
      skeletonId = processingId // Set skeleton ID for consistent animation
      isLoading = true
    }

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

        // First, display the image immediately while processing continues in the background
        await MainActor.run {
          self.selectedImage = image
        }

        // Extract text from the image
        let extractedText = try await ocrManager.extractText(from: processedImage)

        // Save the processed image and get its URL
        let receiptImageURL = saveReceiptImage(processedImage)

        if extractedText.isEmpty {
          print("OCR returned empty text - using image anyway but no text extracted")

          // Still allow the user to manually enter info
          await MainActor.run {
            self.selectedImage = image
            self.temporaryReceiptURL = receiptImageURL
            isLoading = false
            isReceiptProcessing = false
          }
          return
        }

        // Extract merchant and amount
        let extractedMerchant = extractMerchant(from: extractedText)
        let extractedAmount = extractAmount(from: extractedText)

        print("Extracted merchant: \(extractedMerchant)")
        print("Extracted amount: \(extractedAmount)")

        await MainActor.run {
          // We've already set the selectedImage earlier, just update the rest of the UI
          self.merchant = extractedMerchant.isEmpty ? "" : extractedMerchant

          // Store the URL to use when creating the expense
          self.temporaryReceiptURL = receiptImageURL

          if extractedAmount > 0 {
            self.amount = extractedAmount
            self.amountText = String(format: "%.2f", extractedAmount)
          }

          // Complete the processing
          isLoading = false
          isReceiptProcessing = false
        }
      } catch {
        print("Photo processing error: \(error.localizedDescription)")

        await MainActor.run {
          isLoading = false
          isReceiptProcessing = false
        }
      }
    }
  }

  // Save receipt image to local storage and return URL
  private func saveReceiptImage(_ image: UIImage) -> URL? {
    let fileManager = FileManager.default
    do {
      let documentsDirectory = try fileManager.url(
        for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
      )
      let receiptsDirectory = documentsDirectory.appendingPathComponent(
        "Receipts", isDirectory: true
      )

      // Create receipts directory if it doesn't exist
      if !fileManager.fileExists(atPath: receiptsDirectory.path) {
        try fileManager.createDirectory(at: receiptsDirectory, withIntermediateDirectories: true)
      }

      // Generate unique filename with timestamp
      let filename = "\(Date().timeIntervalSince1970)-receipt.jpg"
      let fileURL = receiptsDirectory.appendingPathComponent(filename)

      // Save the image as JPEG
      if let imageData = image.jpegData(compressionQuality: 0.8) {
        try imageData.write(to: fileURL)
        return fileURL
      }
    } catch {
      print("Error saving receipt image: \(error.localizedDescription)")
    }
    return nil
  } // Improve image quality for OCR
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
    Task { @MainActor in
      withAnimation(.easeOut(duration: 0.2)) {
        isLoading = false
        isReceiptProcessing = false
      }
      resetForm()
    }
  }

  private func resetForm() {
    merchant = ""
    category = ""
    amount = 0
    amountText = ""
    selectedPhoto = nil
    selectedImage = nil
    temporaryReceiptURL = nil
    isReceiptProcessing = false
    // We don't reset skeletonId here as it should persist between operations
  }

  // MARK: - Helper Methods  // Method to temporarily show the skeleton loader in the expense list

  // This can be called when we want to show the skeleton animation without actually processing a receipt
  func showSkeletonLoaderTemporarily() {
    Task {
      let tempExpenseId = Int64(Date().timeIntervalSince1970 * 1000)

      // Generate a new skeleton ID to ensure the animation refreshes
      await MainActor.run {
        skeletonId = tempExpenseId
        isReceiptProcessing = true
      }

      // Wait a bit longer before replacing with real content
      try? await Task.sleep(nanoseconds: 800_000_000) // 800ms

      // Create a temporary expense that will replace the skeleton
      let tempExpense = Expense(
        id: tempExpenseId,
        merchant: "Receipt Processed",
        category: "Categorizing...",
        amount: 0.0,
        receiptImageURL: nil,
        timestamp: Date()
      )

      // First add the temporary expense
      await MainActor.run {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          expenses.insert(tempExpense, at: 0)
        }
      }

      // Then hide the skeleton with a slight delay
      try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
      await MainActor.run {
        withAnimation(.easeOut(duration: 0.2)) {
          isReceiptProcessing = false
        }
      }

      // After a brief delay, remove the temporary expense
      try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
      await MainActor.run {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          if let index = expenses.firstIndex(where: { $0.id == tempExpense.id }) {
            expenses.remove(at: index)
          }
        }
      }
    }
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
