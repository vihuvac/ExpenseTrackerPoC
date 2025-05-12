//
//  ImageDetailView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-12.
//

import SwiftUI
import UIKit

struct ImageDetailView: View {
  let image: UIImage
  @State private var scale: CGFloat = 1.0
  @State private var lastScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero
  @State private var isImageLoaded = false
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      // Black background
      Color.black.edgesIgnoringSafeArea(.all)

      // Main content
      VStack {
        // Close button at top
        HStack {
          Spacer()
          Button(action: {
            dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title)
              .foregroundColor(.white)
              .padding()
          }
        }

        Spacer()

        // Show loading indicator while preparing
        if !isImageLoaded {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
        }

        // Image with zoom controls
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .scaleEffect(scale)
          .offset(offset)
          .opacity(isImageLoaded ? 1.0 : 0.0)
          .onAppear {
            // Short delay to ensure proper loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              withAnimation(.easeIn(duration: 0.3)) {
                isImageLoaded = true
              }
            }
          }
          .gesture(
            MagnificationGesture()
              .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                // Limit scale
                scale = min(max(scale * delta, 1.0), 5.0)
              }
              .onEnded { _ in
                lastScale = 1.0
              }
          )
          .gesture(
            DragGesture()
              .onChanged { value in
                // Only allow drag when zoomed in
                if scale > 1.0 {
                  offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                  )
                }
              }
              .onEnded { _ in
                lastOffset = offset
              }
          )
          .gesture(
            TapGesture(count: 2)
              .onEnded {
                // Reset zoom on double tap
                withAnimation {
                  scale = 1.0
                  offset = .zero
                  lastOffset = .zero
                }
              }
          )
          .accessibilityLabel("Receipt image with zoom capability")

        Spacer()

        HStack {
          Button(action: {
            // Zoom out
            withAnimation {
              scale = max(scale - 0.25, 1.0)
              if scale == 1.0 {
                offset = .zero
                lastOffset = .zero
              }
            }
          }) {
            Image(systemName: "minus.circle.fill")
              .font(.largeTitle)
              .foregroundColor(.white)
          }
          .disabled(scale <= 1.0)
          .opacity(scale <= 1.0 ? 0.5 : 1.0)
          .padding()

          Spacer()

          Button(action: {
            // Reset zoom
            withAnimation {
              scale = 1.0
              offset = .zero
              lastOffset = .zero
            }
          }) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
              .font(.largeTitle)
              .foregroundColor(.white)
          }
          .disabled(scale == 1.0 && offset == .zero)
          .opacity(scale == 1.0 && offset == .zero ? 0.5 : 1.0)
          .padding()

          Spacer()

          Button(action: {
            // Zoom in
            withAnimation {
              scale = min(scale + 0.25, 5.0)
            }
          }) {
            Image(systemName: "plus.circle.fill")
              .font(.largeTitle)
              .foregroundColor(.white)
          }
          .disabled(scale >= 5.0)
          .opacity(scale >= 5.0 ? 0.5 : 1.0)
          .padding()
        }
        .padding(.bottom)
      }
    }
  }
}

#Preview {
  ImageDetailView(image: UIImage(systemName: "doc") ?? UIImage())
}
