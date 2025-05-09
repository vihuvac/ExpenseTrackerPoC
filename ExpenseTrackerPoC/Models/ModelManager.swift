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
    let parameters = GenerateParameters(temperature: 0.7, topP: 0.9)
    
    let userInput = UserInput(prompt: fullPrompt)
    
    let maxTokens = 15 // Allow longer words like "Groceries"
    let validCategories = ["Dining", "Transportation", "Entertainment", "Groceries", "Other"]
    
    let result = try await modelContainer.perform { context in
      let lmInput = try await context.processor.prepare(input: userInput)
      
      // Create a dedicated class to track token count within the closure
      // This is thread-safe because it's a reference type used within a single closure
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
        print("Generating: \(text)")
        if counter.count >= maxTokens || text.contains("\n") || text.contains("!") || text.contains(",") {
          return .stop
        }
        return .more
      }
      
      return generationResult.output
    }
    
    let trimmedResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Validate output
    return validCategories.contains(trimmedResult) ? trimmedResult : "Other"
  }
}
