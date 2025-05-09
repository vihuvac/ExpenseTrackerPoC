//
//  ModelManager.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers

class ModelManager {
  static let shared = ModelManager()
  private var modelContainer: ModelContainer?
  
  private init() {}
  
  func loadModel() async throws {
    let configuration = ModelConfiguration(id: "mlx-community/phi-2-hf-4bit-mlx")
    let container = try await LLMModelFactory.shared.loadContainer(configuration: configuration) { progress in
      print("Loading phi-2: \(Int(progress.fractionCompleted * 100))%")
    }
    modelContainer = container
    print("Phi-2 loaded successfully")
  }
  
  func predict(input: String, prompt: String) async throws -> String {
    guard let modelContainer = modelContainer else {
      throw NSError(domain: "Model not loaded", code: -1)
    }
    
    let fullPrompt = "\(prompt)\nMerchant: \(input)"
    let parameters = GenerateParameters(temperature: 0.5, topP: 0.7) // Lower for precision
    
    let userInput = UserInput(prompt: fullPrompt)
    
    let maxTokens = 10
    let validCategories = ["Dining", "Transportation", "Entertainment", "Groceries", "Other"]
    
    // Fallback for common merchants
    let merchantFallback: [String: String] = [
      "walmart": "Groceries",
      "starbucks": "Dining"
    ]
    
    if let fallbackCategory = merchantFallback[input.lowercased()] {
      print("Using fallback for \(input): \(fallbackCategory)")
      return fallbackCategory
    }
    
    let result = try await modelContainer.perform { context in
      let lmInput = try await context.processor.prepare(input: userInput)
      
      final class TokenCounter {
        var count = 0
      }
      let counter = TokenCounter()
      
      let generationResult = try MLXLMCommon.generate(
        input: lmInput,
        parameters: parameters,
        context: context
      ) { tokens in
        counter.count += tokens.count
        let text = context.tokenizer.decode(tokens: tokens)
        let rawTokens = tokens.map { String($0) }.joined(separator: ", ")
        print("Generating: text='\(text)', rawTokens=[\(rawTokens)]")
        if counter.count >= maxTokens ||
          text.contains("\n") ||
          text.contains("!") ||
          text.contains(",") ||
          text.contains(".") ||
          text.contains(" ") ||
          text.contains(";") ||
          validCategories.contains(text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        {
          return .stop
        }
        return .more
      }
      
      return generationResult.output
    }
    
    let trimmedResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
    print("Final output: '\(trimmedResult)'")
    return validCategories.contains(trimmedResult) ? trimmedResult : "Other"
  }
}
