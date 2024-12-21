//
//  ProfileFormPictureField.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import SwiftUI

struct ProfileFormPictureField: View {
    
    @Binding var profileImage: UIImage
    var profileImageUrl: URL?
    var profileImageSize: CGFloat = 200
    
    @State private var showImagePicker: Bool = false
    
    private var padding: CGFloat { 4 }
    private var noUrlImageSize: CGFloat { profileImageSize - (2 * padding) }
    
    var body: some View {
        Button {
            showImagePicker = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                ProfileImageContainer()
                ProfileImageIconOverlay()
            }
        }
        .fullScreenCover(isPresented: $showImagePicker, content: ImagePicker)
    }
    
    @ViewBuilder func ProfileImageContainer() -> some View {
        if profileImage != .init() {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
                .frame(width: noUrlImageSize, height: noUrlImageSize)
                .clipShape(Circle())
                .padding(padding)
                .background(Circle().fill(Color.text))
        } else if profileImageUrl != nil {
            ProfileImageView(
                profileImageUrl,
                size: profileImageSize
            )
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundStyle(Color.background)
                .frame(width: noUrlImageSize, height: noUrlImageSize)
                .clipShape(Circle())
                .padding(padding)
                .background(Circle().fill(Color.text))
        }
    }
    
    @ViewBuilder func ProfileImageIconOverlay() -> some View {
        Image(systemName: "camera.circle.fill")
            .resizable()
            .foregroundStyle(Color.background)
            .frame(width: 48, height: 48)
            .padding(4)
            .background {
                Circle()
                    .foregroundStyle(Color.text)
            }
    }
    
    @ViewBuilder func ImagePicker() -> some View {
        ImagePickerView { selectedImage in
            showImagePicker = false
            profileImage = selectedImage
        } didCancel: {
            showImagePicker = false
        }
        .background(Color.background)
    }
}

#Preview("With Image Url") {
    StatefulPreviewContainer(UIImage()) { image in
        ProfileFormPictureField(
            profileImage: image,
            profileImageUrl: UserData.sample.profileImageUrl
        )
    }
    .background(Color.background)
}

#Preview("Without Image Url") {
    StatefulPreviewContainer(UIImage()) { image in
        ProfileFormPictureField(
            profileImage: image
        )
    }
    .background(Color.background)
}
