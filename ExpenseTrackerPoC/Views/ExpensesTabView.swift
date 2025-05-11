//
//  ExpensesTabView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-11.
//

import PhotosUI
import SwiftUI

struct ExpensesTabView: View {
  @ObservedObject var viewModel: ExpenseViewModel
  @Binding var showForm: Bool
  @Binding var showCamera: Bool

  var body: some View {
    ExpenseListView(
      expenses: viewModel.expenses,
      onDelete: { viewModel.deleteExpense(at: $0) },
      viewModel: viewModel
    )
    .navigationTitle("Expenses")
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        PhotosPicker(
          selection: $viewModel.selectedPhoto,
          matching: .images,
          photoLibrary: .shared()
        ) {
          Image(systemName: "photo")
            .foregroundColor(.blue)
            .accessibilityLabel("Select Receipt Photo")
        }
        .disabled(viewModel.isReceiptProcessing)

        Button(action: { showCamera = true }) {
          Image(systemName: "camera")
            .foregroundColor(.blue)
            .accessibilityLabel("Take Receipt Photo")
        }
        .disabled(viewModel.isReceiptProcessing)

        Button(action: { showForm = true }) {
          Image(systemName: "plus")
            .accessibilityLabel("Add Expense")
        }
      }
    }
    .alert("Error", isPresented: $viewModel.showErrorAlert) {
      Button("OK", role: .cancel) {}
      Button("Retry") { Task { await viewModel.loadModel() } }
    } message: {
      Text(viewModel.errorMessage)
    }
  }
}

#Preview {
  let previewViewModel = ExpenseViewModel(isPreviewMode: true)
  previewViewModel.expenses = [
    Expense(
      id: 1,
      merchant: "Starbucks",
      category: "Dining",
      amount: 20.50,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: 2,
      merchant: "Walmart",
      category: "Electronics",
      amount: 16.98,
      receiptImageURL: nil,
      timestamp: Date()
    ),
  ]

  return NavigationView {
    ExpensesTabView(
      viewModel: previewViewModel,
      showForm: .constant(false),
      showCamera: .constant(false)
    )
  }
}
