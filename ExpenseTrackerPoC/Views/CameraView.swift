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
    picker.cameraCaptureMode = .photo // Explicitly set to photo mode
    picker.videoQuality = .typeHigh // Use high quality to avoid configuration issues
    if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil {
      picker.cameraDevice = .rear
    }
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      if let uiImage = info[.originalImage] as? UIImage {
        print("Camera captured image: \(uiImage.size)")
        parent.image = uiImage
      } else {
        print("Camera failed to capture image")
      }
      parent.dismiss()
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
