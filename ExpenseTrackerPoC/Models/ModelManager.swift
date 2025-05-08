//
//  ModelManager.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation

class ModelManager {
  static let shared = ModelManager()

  private init() {}

  func loadModel() async throws {
    // Mock model loading
    print("Simulating model loading...")
    try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate 1s delay
    print("Model loaded successfully")
  }

  func predict(input: String, prompt: String) async throws -> String {
    // Mock LLM inference
    let fullPrompt = "\(prompt)\nInput: \(input)"
    print("Simulating inference for prompt: \(fullPrompt)")
    // Simple rule-based mock output
    let merchant = input.lowercased()
    if merchant.contains("starbucks") || merchant.contains("coffee") {
      return "Dining"
    } else if merchant.contains("walmart") || merchant.contains("target") {
      return "Groceries"
    } else if merchant.contains("netflix") || merchant.contains("amazon") {
      return "Entertainment"
    }
    return "Other"
  }
}
