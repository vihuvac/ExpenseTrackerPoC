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
  @EnvironmentObject var viewModel: ExpenseViewModel

  var body: some View {
    ZStack {
      MainContentView(viewModel: viewModel)

      if viewModel.isModelLoading {
        LoadingOverlay()
          .transition(.opacity)
      }
    }
  }
}

struct MainContentView: View {
  @ObservedObject var viewModel: ExpenseViewModel
  @State private var showForm = false
  @State private var showCamera = false
  @State private var selectedTab = 0

  var body: some View {
    NavigationView {
      TabView(selection: $selectedTab) {
        ExpenseListView(
          expenses: viewModel.expenses,
          onDelete: { viewModel.deleteExpense(at: $0) },
          viewModel: viewModel
        )
        .tabItem {
          Label("Expenses", systemImage: "list.bullet")
        }
        .tag(0)

        SummaryView(expenses: viewModel.expenses)
          .tabItem {
            Label("Summary", systemImage: "chart.pie")
          }
          .tag(1)
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
      .sheet(isPresented: $showForm) {
        ExpenseFormView(viewModel: viewModel)
          .onDisappear {
            // When the form disappears and processing is happening, make sure we're on the expense tab
            if viewModel.isReceiptProcessing {
              selectedTab = 0
            }
          }
      }
      .sheet(isPresented: $showCamera) {
        CameraView(image: $viewModel.selectedImage)
          .onDisappear {
            // When camera view disappears with an image, make sure to show loading state
            if viewModel.selectedImage != nil {
              // Set loading state immediately when the camera is closed with an image
              viewModel.isReceiptProcessing = true
            }
          }
      }
      .alert("Error", isPresented: $viewModel.showErrorAlert) {
        Button("OK", role: .cancel) {}
        Button("Retry") { Task { await viewModel.loadModel() } }
      } message: {
        Text(viewModel.errorMessage)
      }
      .onChange(of: viewModel.isReceiptProcessing) { _, isProcessing in
        // When processing starts, switch to the expenses tab to make the skeleton loader visible
        if isProcessing {
          withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = 0 // Animate tab change
          }
        }
      }
      .onChange(of: viewModel.selectedPhoto) { _, newItem in
        if newItem != nil {
          // First navigate to the expenses tab to show the skeleton loader
          withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = 0
          }

          // Set loading state after a short delay to allow tab change animation
          Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            await MainActor.run {
              // Set a new unique ID for the skeleton
              viewModel.skeletonId = Int64(Date().timeIntervalSince1970 * 1000)
              viewModel.isReceiptProcessing = true
            }

            // Process the image and show the form
            await viewModel.handlePhotoSelection(newItem)

            // After processing completes, show the form if we have an image
            if viewModel.selectedImage != nil {
              showForm = true
            }
          }
        }
      }
      .onChange(of: viewModel.selectedImage) { _, newImage in
        if newImage != nil {
          // First navigate to the expenses tab to show the skeleton loader
          withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = 0
          }

          // Set loading state after a short delay to allow tab change animation
          Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            await MainActor.run {
              // Set a new unique ID for the skeleton
              viewModel.skeletonId = Int64(Date().timeIntervalSince1970 * 1000)
              viewModel.isReceiptProcessing = true
            }

            // Process the selected image (passing nil since we're using selectedImage directly)
            await viewModel.handlePhotoSelection(nil)

            // Show the form after processing is complete
            showForm = true
          }
        }
      }
    }
    .accentColor(.blue)
    .environment(\.colorScheme, .light)
  }
}

struct LoadingOverlay: View {
  var body: some View {
    ZStack {
      Color(.systemBackground).opacity(0.8)
        .edgesIgnoringSafeArea(.all)
      VStack {
        ProgressView("Loading Model...")
          .progressViewStyle(.circular)
          .padding()
          .background(Color(.systemBackground))
          .cornerRadius(10)
          .shadow(radius: 5)
        Text("This may take a moment")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(ExpenseViewModel())
}
