//
//  ImagePicker.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-09.
//

#if !os(macOS)
import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let useCamera: Bool
    
    init(image: Binding<UIImage?>? = nil, useCamera: Bool) {
        self.useCamera = useCamera
        
        if let image = image {
            self._image = image
            return
        }
        
        self._image = .constant(nil)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        if useCamera {
            let controller = UIImagePickerController()
            controller.sourceType = .camera
            controller.cameraCaptureMode = .photo
            controller.delegate = context.coordinator
            return controller
        }
        
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            defer { picker.dismiss(animated: true) }
            
            if let image = info[.editedImage] as? UIImage {
                self.parent.image = image
                return
            }
            
            if let image = info[.originalImage] as? UIImage {
                self.parent.image = image
            }
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            defer { picker.dismiss(animated: true) }
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { success, error in
                    // There is a common error in the iOS simulator where the image with the pink flowers will cause a crash. This is a problem with the simulator, and production code is not supposed to fail this way. This error has been disabled for this reason.
//                    if let error {
//                        fatalError((error as NSError).localizedDescription)
//                    }
                    
                    self.parent.image = success as? UIImage
                }
            }
        }
    }
}

struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker(image: .constant(nil), useCamera: false)
    }
}
#endif
