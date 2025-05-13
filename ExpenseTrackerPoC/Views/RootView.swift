//
//  RootView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-09.
//

import SwiftUI

struct RootView: View {
  @StateObject private var viewModel = ExpenseViewModel(isPreviewMode: false)

  @State private var isAppLoaded = false
  @State private var isModelLoaded = false
  @State private var minimumSplashTimeElapsed = false

  var body: some View {
    ZStack {
      if !isAppLoaded {
        SplashView()
          .transition(.opacity)
      } else {
        ContentView()
          .environmentObject(viewModel)
          .transition(.opacity)
      }
    }
    .task {
      // Start model loading immediately
      Task {
        await viewModel.loadModel()
        isModelLoaded = true
        checkAndTransition()
      }
      // Ensure minimum splash screen duration
      try? await Task.sleep(nanoseconds: 2_500_000_000)
      minimumSplashTimeElapsed = true
      checkAndTransition()
    }
  }

  private func checkAndTransition() {
    if isModelLoaded && minimumSplashTimeElapsed {
      withAnimation(.easeInOut(duration: 0.7)) {
        isAppLoaded = true
      }
    }
  }
}

#Preview {
  // Create a preview-specific version of RootView that shows the splash screen
  // Note: We use isAppLoaded = false to see the SplashView in the preview
  struct PreviewRootView: View {
    @StateObject private var viewModel = ExpenseViewModel(isPreviewMode: true)
    @State private var isAppLoaded = false

    var body: some View {
      ZStack {
        if !isAppLoaded {
          SplashView()
            .transition(.opacity)
        } else {
          ContentView()
            .environmentObject(viewModel)
            .transition(.opacity)
        }
      }
      // For preview only: auto-transition after a few seconds
      .onAppear {
        // Simulate app loading after 3 seconds in preview
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
          withAnimation(.easeInOut(duration: 0.7)) {
            isAppLoaded = true
          }
        }
      }
    }
  }

  return PreviewRootView()
}
