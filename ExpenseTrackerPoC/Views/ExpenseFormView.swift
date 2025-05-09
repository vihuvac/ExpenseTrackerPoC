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
  @Binding var category: String
  @State private var manualCategory: String = ""

  let isLoading: Bool
  let onCategorize: () async -> Void

  var body: some View {
    VStack(spacing: 15) {
      TextField("Enter Merchant", text: $merchant)
        .disableAutocorrection(true)
        .autocapitalization(.none)
        .textInputAutocapitalization(.never)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray, lineWidth: 1)
        )

      PhotosPicker(
        selection: $selectedPhoto,
        matching: .images,
        photoLibrary: .shared()
      ) {
        Label("Select Receipt", systemImage: "photo")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }

      if let image = selectedImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(height: 150)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }

      Button(action: {
        Task { await onCategorize() }
      }) {
        Text("Categorize")
          .frame(maxWidth: .infinity)
          .padding()
          .background(isLoading ? Color.gray : Color.green)
          .foregroundColor(.white)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .disabled(isLoading || merchant.isEmpty)
      
      if !category.isEmpty {
        Picker("Category", selection: $manualCategory) {
          ForEach(["Dining", "Transportation", "Entertainment", "Groceries", "Electronics", "Other"], id: \.self) {
            Text($0)
          }
        }
        .pickerStyle(.menu)
        .onChange(of: manualCategory) { _, newValue in
          category = newValue
        }
      }
    }
    .padding()
  }
}

#Preview {
  ExpenseFormView(
    merchant: .constant("Starbucks"),
    selectedPhoto: .constant(nil),
    selectedImage: .constant(nil),
    category: .constant("Dining"),
    isLoading: false,
    onCategorize: {}
  )
}
