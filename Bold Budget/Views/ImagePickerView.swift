//
//  ImagePickerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import SwiftUI
import YPImagePicker

struct ImagePickerView: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = YPImagePicker
    
    let didFinishPicking: (UIImage) -> ()
    let didCancel: () -> ()

    init(didFinishPicking: @escaping (UIImage) -> (), didCancel: @escaping () -> ()) {
        self.didFinishPicking = didFinishPicking
        self.didCancel = didCancel
    }
    
    func makeUIViewController(context: Context) -> YPImagePicker {
        let picker = YPImagePicker(configuration: getConfig())
        picker.didFinishPicking { items, cancelled in
            if let selectedImage = items.singlePhoto?.image {
                didFinishPicking(selectedImage)
            } else {
                didCancel()
            }
        }
        return picker
    }
    
    private func configureColors(_ config: inout YPImagePickerConfiguration) {
        //TODO: Make sure all of these colors are good
        config.colors.bottomMenuItemUnselectedTextColor = UIColor(Color.text).withAlphaComponent(0.6)
        config.colors.bottomMenuItemSelectedTextColor = UIColor(Color.text)
        config.colors.tintColor = UIColor(Color.text)
        config.colors.filterBackgroundColor = UIColor(Color.background)
        config.colors.selectionsBackgroundColor = UIColor(Color.background)
        config.colors.safeAreaBackgroundColor = UIColor(Color.background)
        config.colors.assetViewBackgroundColor = UIColor(Color.background)
        config.colors.libraryScreenBackgroundColor = UIColor(Color.background)
        config.colors.bottomMenuItemBackgroundColor = UIColor(Color.background)
        config.colors.photoVideoScreenBackgroundColor = UIColor(Color.background)
        config.colors.defaultNavigationBarColor = UIColor(Color.background)
        config.colors.albumTitleColor = UIColor(Color.text)
        config.colors.albumTintColor = UIColor(Color.text)
        config.colors.defaultNavigationBarColor = UIColor(Color.background)
        config.colors.trimmerHandleColor = UIColor(Color.text)
        config.colors.trimmerMainColor = UIColor(Color.text)
    }
    
    private func configureWordings(_ config: inout YPImagePickerConfiguration) {
        config.wordings.albumsTitle = String(localized: "Albums", comment: "Photo Albums")
        config.wordings.cameraTitle = String(localized: "Camera")
        config.wordings.cancel = String(localized: "Cancel")
        config.wordings.done = String(localized: "Done")
        config.wordings.libraryTitle = String(localized: "Library", comment: "Photo Library")
        config.wordings.next = String(localized: "Next")
        config.wordings.ok = String(localized: "OK")
    }
    
    func getConfig() -> YPImagePickerConfiguration {
        var config = YPImagePickerConfiguration()
        config.showsPhotoFilters = false
        config.shouldSaveNewPicturesToAlbum = false
        config.screens = [.library, .photo]
        config.startOnScreen = .library
        
        configureColors(&config)
        configureWordings(&config)

        if let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String {
            config.albumName = appName
        }
        if let captureIcon = UIImage(systemName: "camera.aperture")?.applyingSymbolConfiguration(.init(font: .boldSystemFont(ofSize: 72))) {
            config.icons.capturePhotoImage = captureIcon
        }
        
        return config
    }

    func updateUIViewController(_ picker: YPImagePicker, context: Context) {
    }
}
