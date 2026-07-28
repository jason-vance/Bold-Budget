//
//  ShareSheet.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/27/26.
//
//  A `UIActivityViewController` wrapper for sharing a file the app just wrote.
//
//  `ShareLink` would be simpler, but it wants its item up front; here the CSV doesn't exist until
//  the user taps Export, so the sheet is presented after the fact with the resulting URL.
//

import SwiftUI
import UIKit

/// A file URL that can drive `.sheet(item:)`.
struct SharedFile: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

struct ShareSheet: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
