//
//  CachedAsyncImage.swift
//  Bold Budget
//
//  Created by Claude on 7/23/26.
//
//  A lightweight async image view with in-memory + on-disk caching, replacing Kingfisher's KFImage.
//  Backed by a dedicated URLCache (disk + memory) plus an NSCache of decoded images, so repeatedly
//  shown avatars aren't re-downloaded or re-decoded.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {

    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            uiImage = await ImageLoader.shared.image(for: url)
        }
    }
}

/// Shared loader that decodes once and caches images in memory, backed by a URLCache for on-disk
/// persistence across launches.
actor ImageLoader {

    static let shared = ImageLoader()

    private let session: URLSession
    private let memoryCache = NSCache<NSURL, UIImage>()

    init() {
        let cache = URLCache(
            memoryCapacity: 20 * 1_024 * 1_024,   // 20 MB
            diskCapacity: 200 * 1_024 * 1_024      // 200 MB
        )
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        // Prefer cached data whenever it exists, matching the "cache aggressively" behavior avatars
        // want (they rarely change and are addressed by unique URLs).
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
    }

    func image(for url: URL?) async -> UIImage? {
        guard let url else { return nil }

        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached
        }

        do {
            let (data, _) = try await session.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            memoryCache.setObject(image, forKey: url as NSURL)
            return image
        } catch {
            return nil
        }
    }
}
