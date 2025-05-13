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
  @State private var showImageDetail: Bool = false

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
            ) { category in
              HStack {
                CategoryIconView(category: category, size: 20)
                  .padding(.trailing, 5)
                Text(category)
              }
            }
          }
          .pickerStyle(.menu)
          .accessibilityLabel("Category picker")
        }

        if let image = viewModel.selectedImage {
          ZStack {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(height: 150)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .accessibilityLabel("Receipt image")

            // Add a subtle overlay to indicate tappability when not processing
            if !viewModel.isReceiptProcessing {
              Color.blue.opacity(0.1)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if viewModel.isReceiptProcessing {
              ZStack {
                Color.black.opacity(0.4)
                VStack {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)
                  Text("Analyzing Receipt...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                  Text("Extracting text and details")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 2)
                }
              }
              .frame(height: 150)
              .cornerRadius(8)
              .transition(.opacity)
              .animation(.easeInOut, value: viewModel.isReceiptProcessing)
            }
          }
          .onTapGesture {
            if !viewModel.isReceiptProcessing {
              showImageDetail = true
            }
          }
        }

        Section {
          PhotosPicker(
            selection: $viewModel.selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
          ) {
            Label(
              "Select Receipt", systemImage: "photo"
            )
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isReceiptProcessing ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("Select receipt photo")
          }
          .disabled(viewModel.isReceiptProcessing)

          Button(action: {
            Task {
              isCategorizing = true // Show loading indicator
              // Dismiss the form before starting the categorization
              // This allows the skeleton loader to be visible in the list view
              dismiss()

              // Add a small delay before processing to allow the form dismissal animation to complete
              try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

              // Now start processing
              await viewModel.categorizeExpense(
                manualCategory: manualCategory.isEmpty ? nil : manualCategory)

              isCategorizing = false // Hide loading indicator

              if !viewModel.showErrorAlert {
                showSuccess = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
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
          Button("Cancel") {
            // Reset the processing state when canceling
            viewModel.cancelProcessing()
            dismiss()
          }
        }

        // Show loading indicator in the toolbar when processing receipt
        ToolbarItem(placement: .primaryAction) {
          if viewModel.isReceiptProcessing {
            ProgressView()
              .progressViewStyle(.circular)
          }
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

        // If we don't have merchant or amount data yet, but do have an image,
        // ensure the processing indicator is shown
        if viewModel.merchant.isEmpty && viewModel.amount == 0 && viewModel.selectedImage != nil {
          // This ensures the loading state is visible even if arriving from a different entry point
          viewModel.isReceiptProcessing = true

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
      .fullScreenCover(isPresented: $showImageDetail) {
        if let image = viewModel.selectedImage {
          ImageDetailView(image: image)
        }
      }
    }
  }
}

#Preview {
  // Use preview mode and add some sample data
  let previewViewModel = ExpenseViewModel(isPreviewMode: true)
  previewViewModel.merchant = "Coffee Shop"
  previewViewModel.amount = 12.99
  previewViewModel.amountText = "12.99"

  return ExpenseFormView(viewModel: previewViewModel)
}
