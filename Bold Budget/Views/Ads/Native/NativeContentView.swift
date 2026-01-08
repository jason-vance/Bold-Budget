//
//  Copyright 2022 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import GoogleMobileAds
import SwiftUI

struct NativeAdListRow: View {
    
    @Binding var ad: Ad?
    let size: AdSize
    
    @State private var showMarketingView: Bool = false
    
    var body: some View {
        VStack {
            switch ad {
            case .native(let nativeAd):
                SimpleNativeAdView(
                    nativeAd: nativeAd,
                    size: size
                )
            case .none:
                Rectangle()
                    .frame(height: getAdFrameHeight(size))
                    .opacity(0)
            }
        }
    }
}

func getAdFrameHeight(_ size: AdSize) -> CGFloat {
    switch size {
    case .small: return 80
    case .medium: return 290
    }
}

struct SimpleNativeAdView: View {

    let nativeAd: NativeAd
    let size: AdSize
    
    private var xibName: String {
        switch size {
        case .small: return "SmallNativeAdView"
        case .medium: return "MediumNativeAdView"
        }
    }
    
    var body: some View {
        NativeAdViewContainer(
            nativeAd: nativeAd,
            xibName: xibName
        )
        .frame(height: getAdFrameHeight(size))
    }
}

private struct NativeAdViewContainer: UIViewRepresentable {
    typealias UIViewType = NativeAdView
    
    let nativeAd: NativeAd
    let xibName: String
    
    func makeUIView(context: Context) -> NativeAdView {
        Bundle.main.loadNibNamed(
            xibName,
            owner: nil,
            options: nil)?.first as! NativeAdView
    }
    
    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        // Each UI property is configurable using your native ad.
        if let headlineView = (nativeAdView.headlineView as? UILabel) {
            headlineView.text = nativeAd.headline
        }

        if let mediaView = nativeAdView.mediaView {
            mediaView.mediaContent = nativeAd.mediaContent
        }
        
        if let bodyView = (nativeAdView.bodyView as? UILabel) {
            bodyView.text = nativeAd.body
        }

        if let iconView = (nativeAdView.iconView as? UIImageView) {
            iconView.image = nativeAd.icon?.image
        }
        
        if let starRatingView = (nativeAdView.starRatingView as? UIImageView) {
            starRatingView.image = imageOfStars(from: nativeAd.starRating)
        }

        if let storeView = (nativeAdView.storeView as? UILabel) {
            storeView.text = nativeAd.store
        }

        if let priceView = (nativeAdView.priceView as? UILabel) {
            priceView.text = nativeAd.price
        }
        
        if let advertiserView = (nativeAdView.advertiserView as? UILabel) {
            advertiserView.text = nativeAd.advertiser
        }
        
        if let callToActionView = (nativeAdView.callToActionView as? UIButton) {
            callToActionView.setTitle(nativeAd.callToAction, for: .normal)
            // For the SDK to process touch events properly, user interaction should be disabled.
            callToActionView.isUserInteractionEnabled = false
        }
        
        // Associate the native ad view with the native ad object. This is required to make the ad
        // clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
    
    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        
        var image: UIImage? = nil
        if rating >= 5 {
            image = UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            image = UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            image = UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            image = UIImage(named: "stars_3_5")
        }
        return image?.withTintColor(UIColor(.yellow))
    }
}
