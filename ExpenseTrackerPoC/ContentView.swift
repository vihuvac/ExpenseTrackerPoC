//
//  ContentView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = ExpenseViewModel()
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Expense Tracker PoC")
          .font(.title)
          .fontWeight(.bold)
        
        if viewModel.isModelLoading {
          ProgressView("Loading Model...")
        } else {
          ExpenseFormView(
            merchant: $viewModel.merchant,
            isLoading: viewModel.isLoading,
            onCategorize: { await viewModel.categorizeExpense() }
          )
          
          if !viewModel.category.isEmpty {
            Text("Category: \(viewModel.category)")
              .font(.headline)
          }
          
          ExpenseListView(expenses: viewModel.expenses)
        }
        
        Spacer()
      }
      .padding()
      .background(Color(.systemGray6))
      .navigationTitle("Expenses")
      .task {
        await viewModel.loadModel()
      }
    }
  }
}

#Preview {
  ContentView()
}
