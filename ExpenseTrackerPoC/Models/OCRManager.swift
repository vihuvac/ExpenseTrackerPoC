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
      throw NSError(domain: "Invalid image", code: -1)
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      let request = VNRecognizeTextRequest { request, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
          continuation.resume(returning: "")
          return
        }
        let text = observations.compactMap { $0.topCandidates(1).first?.string }
          .joined(separator: "\n")
        print("Extracted text: \(text)") // Debug log
        continuation.resume(returning: text)
      }
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
}
