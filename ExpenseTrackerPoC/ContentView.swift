//
//  ContentView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-08.
//

import PhotosUI
import SwiftUI

@MainActor
struct ContentView: View {
  @StateObject private var viewModel = ExpenseViewModel()
  @State private var showForm = false
  @State private var showCamera = false
  @State private var selectedTab = 0

  var body: some View {
    NavigationView {
      ZStack {
        VStack(spacing: 20) {
          if viewModel.isModelLoading {
            ProgressView("Loading Model...")
              .progressViewStyle(.circular)
              .padding()
          } else {
            TabView(selection: $selectedTab) {
              ExpenseListView(
                expenses: viewModel.expenses,
                onDelete: { viewModel.deleteExpense(at: $0) }
              )
              .tabItem {
                Label("Expenses", systemImage: "list.bullet")
              }
              .tag(0)

              // Placeholder for summary dashboard
              VStack {
                Text("Expense Summary")
                  .font(.title2)
                  .padding()
                Text("Total by Category: Coming Soon")
                  .foregroundColor(.gray)
              }
              .tabItem {
                Label("Summary", systemImage: "chart.pie")
              }
              .tag(1)
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .navigationTitle(selectedTab == 0 ? "Expenses" : "Summary")
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            PhotosPicker(
              selection: $viewModel.selectedPhoto,
              matching: .images,
              photoLibrary: .shared()
            ) {
              Image(systemName: "photo")
                .accessibilityLabel("Select Receipt Photo")
            }
            Button(action: { showCamera = true }) {
              Image(systemName: "camera")
                .accessibilityLabel("Take Receipt Photo")
            }
            Button(action: { showForm = true }) {
              Image(systemName: "plus")
                .accessibilityLabel("Add Expense")
            }
          }
        }
        .sheet(isPresented: $showForm) {
          ExpenseFormView(viewModel: viewModel)
        }
        .sheet(isPresented: $showCamera) {
          CameraView(image: $viewModel.selectedImage)
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
          Button("OK", role: .cancel) {}
          Button("Retry") { Task { await viewModel.loadModel() } }
        } message: {
          Text(viewModel.errorMessage)
        }
        .overlay {
          if viewModel.isLoading || viewModel.isModelLoading {
            Color.black.opacity(0.4)
              .edgesIgnoringSafeArea(.all)
            VStack {
              ProgressView(viewModel.isModelLoading ? "Loading Model..." : "Processing...")
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .scaleEffect(1.1)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
              if !viewModel.isModelLoading {
                Button("Cancel") {
                  UINotificationFeedbackGenerator().notificationOccurred(.warning)
                  viewModel.cancelProcessing()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
            }
          }
        }
        .task { await viewModel.loadModel() }
        .onChange(of: viewModel.selectedPhoto) { _, newItem in
          Task { await viewModel.handlePhotoSelection(newItem) }
        }
        .onChange(of: viewModel.selectedImage) { _, newImage in
          if newImage != nil { showForm = true }
        }
      }
    }
    .accentColor(.blue)
    .environment(\.colorScheme, .light) // Adjust for dark mode support
  }
}

#Preview {
  ContentView()
}
