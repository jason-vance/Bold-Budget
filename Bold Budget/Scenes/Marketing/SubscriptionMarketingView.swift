//
//  SubscriptionMarketingView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/10/24.
//

import SwiftUI
import _StoreKit_SwiftUI
import SwinjectAutoregistration

struct SubscriptionMarketingView: View {
    
    @Environment(\.dismiss) var dismiss
    
    private let subscriptionManager = iocContainer~>SubscriptionLevelProvider.self
    
    @State private var isWorking: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.background)
                .ignoresSafeArea()
            SubscriptionStoreView(groupID: subscriptionManager.subscriptionGroupId) {
                MarketingContent()
            }
            .subscriptionStorePickerItemBackground(Color.text.opacity(.opacityButtonBackground))
            .onInAppPurchaseStart { _ in
                withAnimation(.snappy) { isWorking = true }
            }
            .onInAppPurchaseCompletion { product, purchaseResult in
                withAnimation(.snappy) { isWorking = false }
                if case .success(.success(let verificationResult)) = purchaseResult {
                    subscriptionManager.handle(transactionUpdate: verificationResult)
                    dismiss()
                }
            }
        }
        .tint(Color.text)
        .overlay {
            if isWorking {
                BlockingSpinnerView()
            }
        }
    }
    
    @ViewBuilder private func MarketingContent() -> some View {
        VStack {
            Spacer(minLength: 0)
            Image("AuthBg")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .frame(width: 128, height: 128)
                .shadow(radius: .cornerRadiusMedium)
                .padding(.top)
            Text("Bold Budget+")
                .font(.title2.bold())
            Text("Benefits")
                .font(.headline)
                .padding(.top)
            HStack {
                Text("• Create multiple budgets")
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text("• Add other users to your budgets")
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text("• More premium features coming soon")
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text("• No more Ads!")
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding()
    }
}

#Preview {
    SubscriptionMarketingView()
}
