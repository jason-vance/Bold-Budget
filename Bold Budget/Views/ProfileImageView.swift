//
//  ProfileImageView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/12/24.
//

import SwiftUI
import Kingfisher

struct ProfileImageView: View {
    
    var profileImageUrl: URL?
    var size: CGFloat?
    var padding: CGFloat
    
    var imageSize: CGFloat? {
        guard let size = size else { return nil }
        return size - (2 * padding)
    }
    
    init(_ url: URL?, size: CGFloat? = 200, padding: CGFloat = 4) {
        self.profileImageUrl = url
        self.size = size
        self.padding = padding
    }

    var body: some View {
        KFImage(profileImageUrl)
            .resizable()
            .cacheOriginalImage()
            .diskCacheExpiration(.days(7))
//            .forceRefresh()
            .placeholder(PlaceholderView)
            .scaledToFill()
            .frame(width: imageSize, height: imageSize)
            .clipShape(Circle())
            .padding(padding)
            .background(Circle().fill(Color.text))
    }
    
    @ViewBuilder func PlaceholderView() -> some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .foregroundStyle(Color.background)
            .clipShape(Circle())
    }
}

#Preview("Non-placeholder") {
    ProfileImageView(URL(string: "https://cdn.mobygames.com/covers/759944-hyper-light-drifter-collectors-edition-linux-front-cover.jpg")!)
}

#Preview("Placeholder") {
    ProfileImageView(nil)
}
