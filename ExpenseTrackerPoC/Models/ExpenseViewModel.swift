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
        selectedPhoto = nil
        selectedImage = nil
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

  func handlePhotoSelection(_ item: PhotosPickerItem?) async {
    guard let item = item,
          let data = try? await item.loadTransferable(type: Data.self),
          let uiImage = UIImage(data: data) else { return }
    do {
      let text = try await OCRManager.shared.extractText(from: uiImage)
      await MainActor.run {
        selectedImage = uiImage
        merchant = text.split(separator: "\n").first?.trimmingCharacters(in: .whitespaces) ?? ""
      }
    } catch {
      print("OCR error: \(error)")
      await MainActor.run {
        merchant = ""
        selectedImage = nil
      }
    }
  }
}
