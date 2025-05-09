//
//  ExpenseViewModel.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation
import PhotosUI
import SwiftUI
import UIKit

class ExpenseViewModel: ObservableObject {
  @Published var merchant: String = ""
  @Published var category: String = ""
  @Published var isLoading: Bool = false
  @Published var isModelLoading: Bool = true
  @Published var expenses: [Expense] = []
  @Published var selectedPhoto: PhotosPickerItem?
  @Published var selectedImage: UIImage?
  
  private let modelManager = ModelManager.shared
  private let ocrManager = OCRManager.shared
  
  func loadModel() async {
    do {
      try await modelManager.loadModel()
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
    guard !merchant.isEmpty else {
      await MainActor.run { category = "Enter a merchant" }
      return
    }
    await MainActor.run { isLoading = true }
    do {
      let prompt = "Given the merchant name, output exactly one word from: Dining, Transportation, Entertainment, Groceries, Other. Example: For 'Walmart', output 'Groceries'. Merchant: {merchant}"
      let result = try await withTimeout(seconds: 15) {
        try await self.modelManager.predict(input: self.merchant, prompt: prompt)
      }
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
        selectedPhoto = nil
        selectedImage = nil
        isLoading = false
      }
    } catch {
      print("Categorization error: \(error)")
      await MainActor.run {
        category = "Error"
        isLoading = false
      }
    }
  }
  
  func handlePhotoSelection(_ item: PhotosPickerItem?) async {
    guard let item = item,
          let data = try? await item.loadTransferable(type: Data.self),
          let uiImage = UIImage(data: data)
    else {
      await MainActor.run { merchant = "" }
      return
    }
    do {
      let text = try await ocrManager.extractText(from: uiImage)
      print("OCR extracted: \(text)")
      let merchant = extractMerchant(from: text)
      await MainActor.run {
        selectedImage = uiImage
        self.merchant = merchant
      }
    } catch {
      print("OCR error: \(error)")
      await MainActor.run {
        merchant = ""
        selectedImage = nil
      }
    }
  }
  
  private func extractMerchant(from text: String) -> String {
    let lines = text.components(separatedBy: .newlines)
    let merchantKeywords = ["walmart", "starbucks", "cafe", "restaurant", "market", "grocery", "uber", "lyft", "cinema", "theater"]
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
      if merchantKeywords.contains(where: trimmed.contains) {
        return line.trimmingCharacters(in: .whitespaces)
      }
    }
    return lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
  }
  
  // Timeout helper
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
}

struct TimeoutError: Error {}
