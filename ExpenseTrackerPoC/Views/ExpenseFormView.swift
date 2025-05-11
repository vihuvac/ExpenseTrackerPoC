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
  @State private var showSuccess: Bool = false
  @State private var isCategorizing: Bool = false

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Receipt Details")) {
          VStack(alignment: .leading, spacing: 4) {
            TextField("Merchant", text: $viewModel.merchant)
              .disableAutocorrection(true)
              .textInputAutocapitalization(.never)
              .padding()
              .background(Color(.systemBackground))
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
              .accessibilityLabel("Merchant name")
              .onSubmit {
                UIApplication.shared.sendAction(
                  #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                )
              }

            if viewModel.merchant.isEmpty && viewModel.selectedImage != nil {
              Text("Merchant not recognized, please enter manually")
                .font(.caption)
                .foregroundColor(.red)
                .accessibilityLabel("Merchant not recognized, please enter manually")
            }
          }

          VStack(alignment: .leading, spacing: 4) {
            TextField("Amount", text: $amountInput)
              .keyboardType(.decimalPad)
              .padding()
              .background(Color(.systemBackground))
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
              .accessibilityLabel("Expense amount")
              .onSubmit {
                UIApplication.shared.sendAction(
                  #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                )
              }

            if viewModel.amount == 0 && viewModel.selectedImage != nil {
              Text("Amount not recognized, please enter manually")
                .font(.caption)
                .foregroundColor(.red)
                .accessibilityLabel("Amount not recognized, please enter manually")
            }
          }

          Picker("Category", selection: $manualCategory) {
            Text("Select Category").tag("")
            ForEach(
              ["Dining", "Transportation", "Entertainment", "Groceries", "Electronics", "Other"],
              id: \.self
            ) {
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
              isCategorizing = true // Show loading indicator
              await viewModel.categorizeExpense(
                manualCategory: manualCategory.isEmpty ? nil : manualCategory)
              isCategorizing = false // Hide loading indicator
              if !viewModel.showErrorAlert {
                showSuccess = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                  dismiss()
                }
              }
            }
          }) {
            if isCategorizing {
              ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
              Text("Categorize")
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                  viewModel.isLoading || viewModel.merchant.isEmpty || amountInput.isEmpty
                    ? Color.gray : Color.green
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Categorize expense")
            }
          }
          .disabled(
            viewModel.isLoading || viewModel.merchant.isEmpty || amountInput.isEmpty
              || isCategorizing)
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
        print(
          "ExpenseFormView onAppear: amountInput=\(amountInput), viewModel.amountText=\(viewModel.amountText)"
        )
        // Initialize amount input from viewModel
        amountInput = viewModel.amountText

        // Process any camera image that might be present
        // Only process the image if both merchant and amount are empty
        if viewModel.selectedImage != nil && viewModel.merchant.isEmpty && viewModel.amount == 0 {
          print("Processing camera image in ExpenseFormView.onAppear")
          Task {
            await viewModel.handlePhotoSelection(nil)
          }
        }

        if let amount = Double(amountInput) {
          viewModel.amount = amount
        }
      }
      .onChange(of: amountInput) { _, newValue in
        if let amount = Double(newValue) {
          viewModel.amount = amount
        } else {
          viewModel.amount = 0
        }
      }
      .onChange(of: viewModel.amountText) { _, newValue in
        amountInput = newValue
      }
    }
  }
}

#Preview {
  ExpenseFormView(viewModel: ExpenseViewModel())
}
