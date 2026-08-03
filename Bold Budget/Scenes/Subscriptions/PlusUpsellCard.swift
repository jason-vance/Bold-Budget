//
//  PlusUpsellCard.swift
//  Bold Budget
//
//  Created by Jason Vance on 8/3/26.
//
//  A standing "Bold Budget+" entry point, shown on the home screen to anyone who doesn't have it.
//
//  Before this existed, every route to the paywall was conditional: the profile screen's upgrade
//  card behind an unlabelled avatar button, or a gate you had to walk into (a fourth account, a
//  second budget). App Review couldn't find the in-app purchases at all. A tappable card on the
//  first screen after sign-in is the fix — one that is always there, whether or not the user has
//  bumped into a limit yet.
//

import SwiftUI
import SwinjectAutoregistration

struct PlusUpsellCard: View {

    @State private var showPaywall: Bool = false

    @ObservedObject private var featureGate: FeatureGate

    init() {
        self.init(featureGate: iocContainer~>FeatureGate.self)
    }

    init(featureGate: FeatureGate) {
        self.featureGate = featureGate
    }

    var body: some View {
        if !featureGate.isPlus {
            Button { showPaywall = true } label: {
                HStack(spacing: .padding) {
                    IconCircle(systemName: "sparkles", size: 40, tint: .brandTeal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upgrade to Bold Budget+")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appText)
                        Text("Unlimited accounts and budgets, net worth history, sharing, CSV export, and no ads.")
                            .font(.caption)
                            .foregroundStyle(Color.appMutedText)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                // Padded inside the label rather than by `card()` so the whole card is the tap
                // target, matching the nav rows in the profile screen.
                .padding(.padding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .card(0)
            .accessibilityIdentifier("PlusUpsellCard")
            .sheet(isPresented: $showPaywall) { PlusPaywallView(context: .general) }
        }
    }
}

#Preview("Free") {
    VStack {
        PlusUpsellCard(featureGate: .previewFree)
        Spacer()
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Plus") {
    VStack {
        PlusUpsellCard(featureGate: .previewPlus)
        Spacer()
    }
    .padding()
    .background(Color.appBackground)
}
