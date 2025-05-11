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
    do {
      guard let cgImage = image.cgImage else {
        print("Failed to convert UIImage to CGImage")
        throw NSError(
          domain: "Invalid image", code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Failed to convert UIImage to CGImage"]
        )
      }

      return try await withCheckedThrowingContinuation { continuation in
        let request = VNRecognizeTextRequest { request, error in
          if let error = error {
            print("VNRecognizeTextRequest error: \(error)")
            continuation.resume(throwing: error)
            return
          }

          guard let observations = request.results as? [VNRecognizedTextObservation],
                !observations.isEmpty
          else {
            print("No text observations found")
            // Return empty string instead of throwing an error
            continuation.resume(returning: "")
            return
          }

          let text = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
          }.joined(separator: "\n")
          print("VNRecognizeText extracted: \(text)")
          continuation.resume(returning: text)
        }

        // Configure request for better receipt recognition
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        request.customWords = ["total", "subtotal", "tax", "visa", "mastercard", "receipt"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
          try handler.perform([request])
        } catch {
          print("VNImageRequestHandler error: \(error)")
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
             let match = regex.firstMatch(
               in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)
             ),
             let range = Range(match.range(at: 1), in: trimmed),
             let price = Double(trimmed[range])
          {
            let name = trimmed.replacingOccurrences(
              of: "\\s*\\$?\(trimmed[range])\\s*", with: "", options: .regularExpression
            )
            if !name.isEmpty {
              items.append((name: name, price: price))
            }
          }
        }
      }
      return items
    }
  }
}
