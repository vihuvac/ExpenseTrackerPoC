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
      throw NSError(domain: "Model not loaded", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
    }
    
    let fullPrompt = prompt // Use the full prompt provided by ExpenseViewModel
    print("Prompt: \(fullPrompt)")
    
    let parameters = GenerateParameters(temperature: 0.2, topP: 0.7) // Lower temperature for more precise answers
    let userInput = UserInput(prompt: fullPrompt)
    let maxTokens = 15
    let validCategories = ["Dining", "Transportation", "Entertainment", "Groceries", "Electronics", "Other"]
    
    let result = try await modelContainer.perform { context in
      // Tokenize input using context.tokenizer
      let inputTokens = context.tokenizer.encode(text: fullPrompt)
      print("Input tokens: \(inputTokens)")
      
      let lmInput = try await context.processor.prepare(input: userInput)
      
      final class TokenCounter {
        var count = 0
        var output = ""
      }
      let counter = TokenCounter()
      
      let generationResult = try MLXLMCommon.generate(
        input: lmInput,
        parameters: parameters,
        context: context
      ) { tokens in
        counter.count += tokens.count
        
        let text = context.tokenizer.decode(tokens: tokens)
        counter.output += text
        
        print("Intermediate output: '\(text)'")
        
        // Only stop if we have a complete valid category or reach max tokens
        if counter.count >= maxTokens {
          return .stop
        }
        
        // Check if current output contains any valid category
        if let foundCategory = validCategories.first(where: { counter.output.localizedCaseInsensitiveContains($0) }) {
          counter.output = foundCategory
          return .stop
        }
        
        return .more
      }
      
      return generationResult.output
    }
    
    let trimmedResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
    print("Final output: '\(trimmedResult)'")
    
    // Find the first valid category in the output (case insensitive)
    if let foundCategory = validCategories.first(where: { trimmedResult.localizedCaseInsensitiveContains($0) }) {
      return foundCategory
    }
    
    return "Other"
  }
}
