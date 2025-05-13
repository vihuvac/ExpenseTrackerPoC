//
//  ExpenseIconView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-12.
//

import SwiftUI
import UIKit

struct ExpenseIconView: View {
  let expense: Expense
  let iconSize: CGFloat
  let imageSize: CGFloat

  @State private var showImageDetail = false
  @State private var uiImage: UIImage?
  @State private var isImageLoaded = false

  init(expense: Expense, iconSize: CGFloat = 40, imageSize: CGFloat = 80) {
    self.expense = expense
    self.iconSize = iconSize
    self.imageSize = imageSize
  }

  private func loadImage(from url: URL) -> UIImage? {
    do {
      let imageData = try Data(contentsOf: url)
      return UIImage(data: imageData)
    } catch {
      print("Error loading image: \(error)")
      return nil
    }
  }

  var body: some View {
    // If there's a receipt image, show it
    if let receiptURL = expense.receiptImageURL {
      ZStack {
        if let image = uiImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: imageSize, height: imageSize)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 1)
            .accessibilityLabel("Receipt image")
        } else {
          // Show loading placeholder
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: imageSize, height: imageSize)
            .overlay(
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.0)
            )
        }

        // Add a subtle overlay to indicate tappability
        if uiImage != nil {
          Color.blue.opacity(0.1)
            .frame(width: imageSize, height: imageSize)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      }
      .onAppear {
        // Load the image on appear
        if uiImage == nil {
          DispatchQueue.global(qos: .userInitiated).async {
            let image = loadImage(from: receiptURL)
            DispatchQueue.main.async {
              self.uiImage = image
              self.isImageLoaded = true
            }
          }
        }
      }
      .onTapGesture {
        if uiImage != nil {
          showImageDetail = true
        }
      }
      .fullScreenCover(isPresented: $showImageDetail) {
        if let displayImage = uiImage {
          ImageDetailView(image: displayImage)
        } else {
          // Fallback if image isn't available for some reason
          Color.black
            .overlay(
              VStack {
                Text("Unable to load image")
                  .foregroundColor(.white)
                Button("Close") {
                  showImageDetail = false
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
                .padding(.top, 20)
              }
            )
            .edgesIgnoringSafeArea(.all)
        }
      }
    } else {
      // Otherwise show the category icon
      CategoryIconView(category: expense.category, size: iconSize)
        .accessibilityLabel("Category: \(expense.category)")
    }
  }
}

#Preview {
  ExpenseIconView(
    expense: Expense(
      id: 2,
      merchant: "McDonalds",
      category: "Dining",
      amount: 12.50,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    iconSize: 60.0,
    imageSize: 80.0
  )
}
