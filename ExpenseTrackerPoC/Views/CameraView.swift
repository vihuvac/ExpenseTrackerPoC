//
//  CameraView.swift
//  ExpenseTrackerPoC
//
//  Created by Víctor Hugo Valle Castillo on 2025-05-09.
//

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  @Environment(\.presentationMode) var presentationMode
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let image = info[.originalImage] as? UIImage {
        parent.image = image
      }
      parent.presentationMode.wrappedValue.dismiss()
    }
  }
}

#Preview {
    CameraView(image: .constant(nil))
}
