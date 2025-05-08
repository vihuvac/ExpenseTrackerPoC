//
//  ExpenseFormView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import PhotosUI
import SwiftUI

struct ExpenseFormView: View {
  @Binding var merchant: String
  @Binding var selectedPhoto: PhotosPickerItem?
  @Binding var selectedImage: UIImage?

  let isLoading: Bool
  let onCategorize: () async -> Void

  var body: some View {
    VStack(spacing: 10) {
      TextField("Enter merchant (e.g., Starbucks)", text: $merchant)
        .textFieldStyle(.roundedBorder)
        .disableAutocorrection(true)
        .padding(.horizontal)

      PhotosPicker("Scan Receipt", selection: $selectedPhoto, matching: .images)
        .padding(.horizontal)

      if let selectedImage {
        Image(uiImage: selectedImage)
          .resizable()
          .scaledToFit()
          .frame(height: 100)
      }

      Button(action: {
        Task { await onCategorize() }
      }) {
        Text(isLoading ? "Processing..." : "Categorize")
          .frame(maxWidth: .infinity)
          .padding()
          .background(isLoading ? Color.gray : Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      .disabled(isLoading || merchant.isEmpty)
      .padding(.horizontal)
    }
  }
}

#Preview {
  ExpenseFormView(
    merchant: .constant("Starbucks"),
    selectedPhoto: .constant(nil),
    selectedImage: .constant(nil),
    isLoading: false,
    onCategorize: {}
  )
}
