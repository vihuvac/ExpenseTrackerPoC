//
//  ContentView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import SwiftUI

@MainActor
struct ContentView: View {
  @StateObject private var viewModel = ExpenseViewModel()
  
  var body: some View {
    NavigationView {
      ZStack {
        VStack(spacing: 20) {
          Text("Expense Tracker PoC")
            .font(.title)
            .fontWeight(.bold)
          
          if viewModel.isModelLoading {
            ProgressView("Loading Model...")
          } else if viewModel.isLoading {
            ProgressView("Categorizing...")
          } else {
            ExpenseFormView(
              merchant: $viewModel.merchant,
              selectedPhoto: $viewModel.selectedPhoto,
              selectedImage: $viewModel.selectedImage,
              category: $viewModel.category,
              isLoading: viewModel.isLoading,
              onCategorize: { await viewModel.categorizeExpense() }
            )
            .onChange(of: viewModel.selectedPhoto) { _, newItem in
              Task { await viewModel.handlePhotoSelection(newItem) }
            }
            
            if !viewModel.category.isEmpty {
              Text("Category: \(viewModel.category)")
                .font(.headline)
            }
            
            ExpenseListView(
              expenses: viewModel.expenses,
              onDelete: { indexSet in
                viewModel.deleteExpense(at: indexSet)
              }
            )
          }
          
          Spacer()
          
          if !viewModel.errorMessage.isEmpty {
            Text(viewModel.errorMessage)
              .foregroundColor(.red)
              .padding()
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .navigationTitle("Expenses")
        .task {
          await viewModel.loadModel()
        }
        
        if viewModel.isModelLoading || viewModel.isLoading {
          Color.black.opacity(0.4)
            .edgesIgnoringSafeArea(.all)
          
          VStack {
            ProgressView(viewModel.isModelLoading ? "Loading Model..." : "Processing...")
              .padding()
              .background(Color.white)
              .cornerRadius(10)
            
            if !viewModel.isModelLoading {
              Button("Cancel") {
                viewModel.cancelProcessing()
              }
              .padding()
            }
          }
        }
      }
      .alert("Error", isPresented: $viewModel.showErrorAlert) {
        Button("OK", role: .cancel) { }
        Button("Retry") {
          Task { await viewModel.loadModel() }
        }
      } message: {
        Text(viewModel.errorMessage)
      }
    }
  }
}

#Preview {
  ContentView()
}
