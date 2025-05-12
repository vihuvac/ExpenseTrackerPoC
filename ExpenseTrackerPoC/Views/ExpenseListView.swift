//
//  ExpenseListView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import SwiftUI
import UIKit

struct ExpenseListView: View {
  let expenses: [Expense]
  var onDelete: ((IndexSet) -> Void)?

  @ObservedObject var viewModel: ExpenseViewModel

  @State private var showDeleteConfirmation = false
  @State private var deleteOffsets: IndexSet?

  var body: some View {
    List {
      // Show "No expenses yet" message when the list is empty and not processing
      if expenses.isEmpty && !viewModel.isReceiptProcessing {
        Text("No expenses yet")
          .foregroundColor(.gray)
          .frame(maxWidth: .infinity, alignment: .center)
          .accessibilityLabel("No expenses")
          .listRowSeparator(.hidden)
      }

      // In SwiftUI lists, new items are added at the top, so we need to
      // position the skeleton loader at the top for new expenses
      if viewModel.isReceiptProcessing {
        SkeletonLoadingView(showText: true, id: viewModel.skeletonId)
          .background(Color(.systemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .shadow(radius: 2)
          .listRowSeparator(.hidden)
          .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
          .transition(
            .asymmetric(
              insertion: .opacity.combined(
                with: .scale(scale: 0.95).combined(with: .offset(y: -20))),
              removal: .opacity
            )
          )
      }

      ForEach(expenses) { expense in
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Merchant: \(expense.merchant)")
              .font(.headline)
            Text("Category: \(expense.category)")
            Text("Amount: $\(String(format: "%.2f", expense.amount))")
            Text("Date: \(expense.timestamp, style: .date)")
              .font(.caption)
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)

          // Display receipt image if available
          if let receiptURL = expense.receiptImageURL,
             let imageData = try? Data(contentsOf: receiptURL),
             let image = UIImage(data: imageData)
          {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(maxWidth: 100, maxHeight: 100)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .padding(.trailing, 8)
          } else {
            // Display category icon when no receipt image
            CategoryIconView(category: expense.category, size: 50)
              .padding(.trailing, 12)
          }
        }
        .id(expense.id) // Make sure each expense has a stable ID
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
          "Expense: \(expense.merchant), \(expense.category), $\(String(format: "%.2f", expense.amount))"
        )
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .transition(
          .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95).combined(with: .offset(y: 20))),
            removal: .opacity.combined(with: .scale(scale: 0.95))
          )
        )
      }
      .onDelete { offsets in
        deleteOffsets = offsets
        showDeleteConfirmation = true
      }
    }
    .listStyle(PlainListStyle())
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isReceiptProcessing)
    .alert("Delete Expense", isPresented: $showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let offsets = deleteOffsets {
          withAnimation(.easeInOut) {
            onDelete?(offsets)
          }
        }
      }
    } message: {
      Text("Are you sure you want to delete this expense?")
    }
  }
}

#Preview {
  let previewViewModel = ExpenseViewModel(isPreviewMode: true)
  let sampleExpenses = [
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
    Expense(
      id: 3,
      merchant: "Uber",
      category: "Transportation",
      amount: 25.00,
      receiptImageURL: nil,
      timestamp: Date()
    ),
    Expense(
      id: 4,
      merchant: "Amazon",
      category: "Shopping",
      amount: 67.45,
      receiptImageURL: nil,
      timestamp: Date()
    ),
  ]

  // Optional: simulate skeleton loading for preview
  // previewViewModel.isReceiptProcessing = true

  return ExpenseListView(
    expenses: sampleExpenses,
    viewModel: previewViewModel
  )
}
