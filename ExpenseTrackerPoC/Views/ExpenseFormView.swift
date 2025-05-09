//
//  ExpenseFormView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import PhotosUI
import SwiftUI

struct ExpenseFormView: View {
  @ObservedObject var viewModel: ExpenseViewModel
  @Environment(\.dismiss) var dismiss
  
  @State private var amountInput: String = ""
  @State private var manualCategory: String = ""
  @State private var showSuccess = false
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Receipt Details")) {
          TextField("Merchant", text: $viewModel.merchant)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
            .accessibilityLabel("Merchant name")
            .onSubmit { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
          
          VStack(alignment: .leading, spacing: 4) {
            TextField("Amount", text: $amountInput)
              .keyboardType(.decimalPad)
              .padding()
              .background(Color(.systemBackground))
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
              .accessibilityLabel("Expense amount")
              .onSubmit { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            
            if viewModel.amount == 0 && !amountInput.isEmpty {
              Text("Amount not recognized, please enter manually")
                .font(.caption)
                .foregroundColor(.red)
                .accessibilityLabel("Amount not recognized, please enter manually")
            }
          }
          
          Picker("Category", selection: $manualCategory) {
            Text("Select Category").tag("")
            ForEach(["Dining", "Transportation", "Entertainment", "Groceries", "Electronics", "Other"], id: \.self) {
              Text($0)
            }
          }
          .pickerStyle(.menu)
          .accessibilityLabel("Category picker")
        }
        
        if let image = viewModel.selectedImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("Receipt image")
        }
        
        Section {
          PhotosPicker(
            selection: $viewModel.selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
          ) {
            Label("Select Receipt", systemImage: "photo")
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.blue)
              .foregroundColor(.white)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .accessibilityLabel("Select receipt photo")
          }
          
          Button(action: {
            Task {
              await viewModel.categorizeExpense(manualCategory: manualCategory.isEmpty ? nil : manualCategory)
              if !viewModel.showErrorAlert {
                showSuccess = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                  dismiss()
                }
              }
            }
          }) {
            Text("Categorize")
              .frame(maxWidth: .infinity)
              .padding()
              .background(viewModel.isLoading || viewModel.merchant.isEmpty || amountInput.isEmpty ? Color.gray : Color.green)
              .foregroundColor(.white)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .accessibilityLabel("Categorize expense")
          }
          .disabled(viewModel.isLoading || viewModel.merchant.isEmpty || amountInput.isEmpty)
        }
      }
      .navigationTitle("Add Expense")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .overlay {
        if showSuccess {
          Image(systemName: "checkmark.circle.fill")
            .resizable()
            .frame(width: 50, height: 50)
            .foregroundColor(.green)
            .scaleEffect(1.2)
            .animation(.spring(), value: showSuccess)
        }
      }
      .onAppear {
        // Initialize amountInput with viewModel.amountText
        amountInput = viewModel.amountText
        // Update viewModel.amount when amountInput changes
        if let amount = Double(amountInput) {
          viewModel.amount = amount
        }
      }
      .onChange(of: amountInput) { _, newValue in
        // Sync viewModel.amount with amountInput
        if let amount = Double(newValue) {
          viewModel.amount = amount
        } else {
          viewModel.amount = 0
        }
      }
      .onChange(of: viewModel.amountText) { _, newValue in
        // Update amountInput when viewModel.amountText changes (e.g., from OCR)
        amountInput = newValue
      }
    }
  }
}

#Preview {
  ExpenseFormView(viewModel: ExpenseViewModel())
}
