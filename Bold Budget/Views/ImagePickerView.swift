//
//  ImagePickerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import SwiftUI
import PhotosUI

/// A single-image library picker built on the system `PHPickerViewController`. Exposes the same
/// `didFinishPicking` / `didCancel` callbacks the rest of the app already relies on.
struct ImagePickerView: UIViewControllerRepresentable {

    let didFinishPicking: (UIImage) -> ()
    let didCancel: () -> ()

    init(didFinishPicking: @escaping (UIImage) -> (), didCancel: @escaping () -> ()) {
        self.didFinishPicking = didFinishPicking
        self.didCancel = didCancel
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: PHPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {

        private let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self)
            else {
                parent.didCancel()
                return
            }

            provider.loadObject(ofClass: UIImage.self) { [parent] object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        parent.didFinishPicking(image)
                    } else {
                        parent.didCancel()
                    }
                }
            }
        }
    }
}
