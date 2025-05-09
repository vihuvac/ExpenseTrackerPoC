//
//  OCRManager.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import Foundation
import UIKit
import Vision

class OCRManager {
  static let shared = OCRManager()
  
  private init() {}
  
  func extractText(from image: UIImage) async throws -> String {
    guard let cgImage = image.cgImage else {
      throw NSError(domain: "Invalid image", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      let request = VNRecognizeTextRequest { request, error in
        if let error = error {
          print("OCR error: \(error)")
          continuation.resume(throwing: error)
          return
        }
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
          continuation.resume(returning: "")
          return
        }
        let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        print("Extracted text: \(text)")
        continuation.resume(returning: text)
      }
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        print("OCR handler error: \(error)")
        continuation.resume(throwing: error)
      }
    }
  }
  
  func extractItems(from text: String) -> [(name: String, price: Double?)] {
    let lines = text.components(separatedBy: .newlines)
    var items: [(name: String, price: Double?)] = []
    let pricePattern = "\\$?(\\d+\\.\\d{2})"
    
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.contains("$") || trimmed.contains(".") {
        if let regex = try? NSRegularExpression(pattern: pricePattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let range = Range(match.range(at: 1), in: trimmed),
           let price = Double(trimmed[range])
        {
          let name = trimmed.replacingOccurrences(of: "\\s*\\$?\(trimmed[range])\\s*", with: "", options: .regularExpression)
          if !name.isEmpty {
            items.append((name: name, price: price))
          }
        }
      }
    }
    return items
  }
}
