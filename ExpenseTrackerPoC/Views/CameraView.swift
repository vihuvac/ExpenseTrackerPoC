//
//  CameraView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-09.
//

import AVFoundation
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  @Environment(\.dismiss) var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = .camera
    picker.cameraCaptureMode = .photo // Ensure photo mode
    picker.cameraDevice = .rear // Directly set to rear camera
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: CameraView

    init(_ parent: CameraView) {
      self.parent = parent
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let uiImage = info[.originalImage] as? UIImage {
        print("Camera captured image: \(uiImage.size)")

        // Process the image to ensure it's properly oriented
        if let fixedImage = fixImageOrientation(uiImage) {
          parent.image = fixedImage
          print("Image orientation fixed and assigned to binding")
        } else {
          parent.image = uiImage
          print("Using original image (orientation fix failed)")
        }
      } else {
        print("Camera failed to capture image")
      }
      parent.dismiss()
    }

    private func fixImageOrientation(_ image: UIImage) -> UIImage? {
      // Images from camera are sometimes rotated incorrectly
      UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
      defer { UIGraphicsEndImageContext() }

      image.draw(in: CGRect(origin: .zero, size: image.size))
      return UIGraphicsGetImageFromCurrentImageContext()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      print("Camera cancelled")
      parent.dismiss()
    }
  }
}

#Preview {
  CameraView(image: .constant(nil))
}
