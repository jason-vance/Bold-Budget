//
//  AdProvider.swift
//  Dipply
//
//  Created by Jason Vance on 4/25/25.
//

import Combine
import Foundation
import GoogleMobileAds
import SwiftUI

class AdProviderFactory: ObservableObject {
    
    @Published var ad: Ad? = nil
    var adPublisher: AnyPublisher<Ad?, Never> { $ad.eraseToAnyPublisher() }
    
    private let factory: () -> AdProvider
    
    init(
        factory: @escaping () -> AdProvider
    ) {
        self.factory = factory
    }
    
    func createAdProvider() -> AdProvider {
        factory()
    }
}

extension AdProviderFactory {
    
    static let forDev = AdProviderFactory { NativeAdViewModel() }
    
    static let forProd = AdProviderFactory { NativeAdViewModel() }
    
    static let forScreenshots = AdProviderFactory { MockAdProvider() }
}

extension View {
    func adContainer(factory: AdProviderFactory, adProvider: Binding<AdProvider?>, ad: Binding<Ad?>) -> some View {
        self
            .onAppear {
                if adProvider.wrappedValue == nil {
                    adProvider.wrappedValue = factory.createAdProvider()
                }
                adProvider.wrappedValue!.refreshAd()
            }
            .onReceive(adProvider.wrappedValue?.adPublisher ?? factory.adPublisher) { ad.wrappedValue = $0 }
            .animation(.snappy, value: ad.wrappedValue == nil)
    }
}



protocol AdProvider {
    var adPublisher: AnyPublisher<Ad?, Never> { get }
    var errorPublisher: AnyPublisher<Error?, Never> { get }
    func refreshAd()
}

enum Ad {
    case native(NativeAd)
}

fileprivate class MockAdProvider: AdProvider {
    
    @Published var ad: Ad?
    @Published var error: Error?
    
    var adPublisher: AnyPublisher<Ad?, Never> { $ad.eraseToAnyPublisher() }
    var errorPublisher: AnyPublisher<Error?, Never> { $error.eraseToAnyPublisher() }
    
    func refreshAd() { }
}
