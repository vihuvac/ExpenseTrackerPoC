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
  @State private var isAppLoaded = false
  
  var body: some View {
    ZStack {
      if !isAppLoaded {
        SplashView()
          .transition(.opacity)
      } else {
        MainContentView(viewModel: viewModel)
      }
      
      if viewModel.isModelLoading {
        LoadingOverlay()
          .transition(.opacity)
      }
    }
    .task {
      let start = Date()
      await viewModel.loadModel()
      print("Model loaded in \(Date().timeIntervalSince(start)) seconds")
      withAnimation(.easeInOut(duration: 0.5)) {
        isAppLoaded = true
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
          onDelete: { viewModel.deleteExpense(at: $0) }
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
      .onChange(of: viewModel.selectedPhoto) { _, newItem in
        Task { await viewModel.handlePhotoSelection(newItem) }
      }
      .onChange(of: viewModel.selectedImage) { _, newImage in
        if newImage != nil { showForm = true }
      }
    }
    .accentColor(.blue)
    .environment(\.colorScheme, .light)
  }
}

struct SplashView: View {
  var body: some View {
    ZStack {
      Color(.systemBackground)
        .edgesIgnoringSafeArea(.all)
      VStack {
        Image(systemName: "dollarsign.circle.fill")
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)
          .foregroundColor(.blue)
        Text("Expense Tracker")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.primary)
        Text("Track your expenses with ease")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
    }
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
}
