//
//  SkeletonLoadingView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-11.
//

import SwiftUI
import UIKit

struct SkeletonLoadingView: View {
  @State private var isAnimating = false
  @State private var pulsate = false

  var showText: Bool = true
  var id: Int64? = nil

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        if showText {
          Text("New Receipt Processing...")
            .font(.headline)
            .foregroundColor(.gray)
            .scaleEffect(pulsate ? 1.02 : 1.0)
            .animation(
              Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulsate
            )

          // Animated progress indicator
          ProgressView()
            .progressViewStyle(.circular)
            .scaleEffect(1.0)
            .tint(.gray)
            .padding(.bottom, 4)
        }

        SkeletonRectangle(width: 200, height: 20)
        SkeletonRectangle(width: 150, height: 20)
        SkeletonRectangle(width: 120, height: 20)
        SkeletonRectangle(width: 180, height: 16)
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)

      // Receipt image placeholder
      SkeletonRectangle(width: 100, height: 100)
        .padding(.trailing, 8)
    }
    .onAppear {
      pulsate = true
      withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
        isAnimating = true
      }
    }
  }
}

struct SkeletonRectangle: View {
  var width: CGFloat
  var height: CGFloat
  @State private var isAnimating = false

  var body: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(
        LinearGradient(
          gradient: Gradient(colors: [
            Color.gray.opacity(0.2), Color.gray.opacity(0.5), Color.gray.opacity(0.2),
          ]),
          startPoint: .leading,
          endPoint: UnitPoint(x: isAnimating ? 2.5 : -0.5, y: 0)
        )
      )
      .frame(width: width, height: height)
      .onAppear {
        withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
          isAnimating = true
        }
      }
  }
}

#Preview {
  SkeletonLoadingView()
}
