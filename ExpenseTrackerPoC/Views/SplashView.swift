//
//  SplashView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-12.
//

import SwiftUI
import UIKit

struct SplashView: View {
  // Animation state properties
  @State private var isAnimating = false
  @State private var iconScale: CGFloat = 0.3
  @State private var iconOpacity: Double = 0
  @State private var titleOpacity: Double = 0
  @State private var subtitleOpacity: Double = 0
  @State private var showGradient = false
  @State private var pulseEffect: CGFloat = 1.0
  @State private var rotationDegrees: Double = 0

  // Environment for detecting dark mode
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      // Background with animated gradient that adapts to dark/light mode
      LinearGradient(
        gradient: Gradient(
          colors: showGradient
            ? [
              Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.2),
              Color(UIColor.systemBackground),
              Color.blue.opacity(colorScheme == .dark ? 0.1 : 0.15),
            ]
            : [Color(UIColor.systemBackground), Color(UIColor.systemBackground)]
        ),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
      .animation(.easeInOut(duration: 1.8), value: showGradient)

      VStack(spacing: 16) {
        // App icon with bounce animation
        ZStack {
          // Subtle rotating glow effect behind icon
          Circle()
            .fill(Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.2))
            .frame(width: 110, height: 110)
            .scaleEffect(pulseEffect)
            .rotationEffect(.degrees(rotationDegrees))
            .blur(radius: 8)
            .opacity(iconOpacity * 0.8)

          Image(systemName: "dollarsign.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundColor(.blue)
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
            .shadow(
              color: colorScheme == .dark
                ? Color.black.opacity(0.3)
                : Color.blue.opacity(0.3),
              radius: 6,
              x: 0,
              y: 4
            )
        }

        // App title with fade-in animation
        Text("Expense Tracker")
          .font(.system(size: 36, weight: .bold, design: .rounded))
          .foregroundColor(.primary)
          .opacity(titleOpacity)
          .shadow(
            color: colorScheme == .dark
              ? Color.black.opacity(0.3)
              : Color.gray.opacity(0.2),
            radius: 1,
            x: 0,
            y: 1
          )

        // Subtitle with fade-in and slight slide-up animation
        Text("Track your expenses with ease")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .opacity(subtitleOpacity)
          .padding(.top, 4)
          .offset(y: subtitleOpacity == 0 ? 10 : 0)
      }
    }
    .onAppear {
      // Trigger animations sequentially
      withAnimation(.easeIn(duration: 0.3)) {
        showGradient = true
      }

      withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
        iconScale = 1.0
        iconOpacity = 1
      }

      withAnimation(.easeInOut(duration: 0.6).delay(0.6)) {
        titleOpacity = 1
      }

      withAnimation(.easeInOut(duration: 0.6).delay(0.9)) {
        subtitleOpacity = 1
      }

      // Start pulse and rotation animations after the main animations
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
        // Continuous pulse animation
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
          pulseEffect = 1.08
        }

        // Continuous slow rotation
        withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
          rotationDegrees = 360
        }
      }
    }
  }
}

#Preview {
  SplashView()
}
