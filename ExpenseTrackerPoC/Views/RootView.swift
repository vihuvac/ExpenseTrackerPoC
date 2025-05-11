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

  var body: some View {
    ZStack {
      if !isAppLoaded {
        SplashView()
          .transition(.opacity)
      } else {
        ContentView()
          .environmentObject(viewModel)
      }
    }
    .task {
      await viewModel.loadModel()
      withAnimation(.easeInOut(duration: 0.5)) {
        isAppLoaded = true
      }
    }
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

#Preview {
  // Create a preview-specific version of RootView that skips loading
  struct PreviewRootView: View {
    @StateObject private var viewModel = ExpenseViewModel(isPreviewMode: true)
    @State private var isAppLoaded = true // Start with app loaded for preview

    var body: some View {
      ZStack {
        if !isAppLoaded {
          SplashView()
            .transition(.opacity)
        } else {
          ContentView()
            .environmentObject(viewModel)
        }
      }
    }
  }

  return PreviewRootView()
}
