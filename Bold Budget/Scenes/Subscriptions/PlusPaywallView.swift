//
//  PlusPaywallView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/27/26.
//
//  The Bold Budget+ paywall, in the redesign palette.
//
//  Hand-rolled rather than `SubscriptionStoreView` because the lifetime unlock is a non-consumable
//  and can't live inside a subscription group's store view; splitting the three products across two
//  UIs reads worse than presenting them as three plans. Everything `SubscriptionStoreView` would
//  have given for free — localized prices, trial eligibility, the renewal disclosure, restore, and
//  the terms links — is therefore provided explicitly below.
//

import StoreKit
import SwiftUI
import SwinjectAutoregistration

struct PlusPaywallView: View {

    @Environment(\.dismiss) private var dismiss

    let context: PaywallContext

    @StateObject private var store: PlusStore

    @State private var selectedProductId: String = BoldBudgetProduct.yearlyId
    @State private var showTermsOfService: Bool = false
    @State private var showPrivacyPolicy: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init(context: PaywallContext = .general) {
        self.init(
            context: context,
            subscriptionLevelProvider: iocContainer~>SubscriptionLevelProvider.self
        )
    }

    init(
        context: PaywallContext,
        subscriptionLevelProvider: SubscriptionLevelProvider
    ) {
        self.context = context
        self._store = .init(wrappedValue: PlusStore(subscriptionLevelProvider: subscriptionLevelProvider))
    }

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedProductId }
    }

    /// The free trial on the selected plan, if this Apple ID is still eligible. Only subscriptions
    /// carry one — the lifetime product has no `subscription` and falls out here.
    private var trialPeriod: Product.SubscriptionPeriod? {
        guard store.isEligibleForIntroOffer,
              let offer = selectedProduct?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial
        else { return nil }
        return offer.period
    }

    /// The trial length in words, e.g. "7 days", "1 week". Written out rather than normalized to
    /// days because App Store Connect offers are configured in whatever unit the developer picked,
    /// and restating a 1-week offer as "7 days" would misdescribe the product.
    private var trialDescription: String? {
        guard let period = trialPeriod else { return nil }
        let count = period.value
        switch period.unit {
        case .day: return count == 1 ? String(localized: "1 day") : String(localized: "\(count) days")
        case .week: return count == 1 ? String(localized: "1 week") : String(localized: "\(count) weeks")
        case .month: return count == 1 ? String(localized: "1 month") : String(localized: "\(count) months")
        case .year: return count == 1 ? String(localized: "1 year") : String(localized: "\(count) years")
        @unknown default: return nil
        }
    }

    private var callToActionTitle: String {
        if trialPeriod != nil { return String(localized: "Start Free Trial") }
        if selectedProductId == BoldBudgetProduct.lifetimeId { return String(localized: "Unlock Forever") }
        return String(localized: "Continue")
    }

    private func buy() {
        guard let product = selectedProduct else { return }

        Task {
            do {
                let outcome = try await store.purchase(product)
                switch outcome {
                case .purchased: dismiss()
                case .cancelled: break
                case .pending: show(alert: String(localized: "Your purchase is pending approval. Bold Budget+ will unlock once it's approved."))
                }
            } catch {
                show(alert: String(localized: "The purchase couldn't be completed. \(error.localizedDescription)"))
            }
        }
    }

    private func restore() {
        Task {
            do {
                let didRestore = try await store.restorePurchases()
                if didRestore {
                    dismiss()
                } else {
                    show(alert: String(localized: "No previous Bold Budget+ purchase was found on this Apple Account."))
                }
            } catch {
                show(alert: String(localized: "Couldn't restore purchases. \(error.localizedDescription)"))
            }
        }
    }

    private func show(alert: String) {
        alertMessage = alert
        showAlert = true
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    Hero()
                    FeatureList()
                    Plans()
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            Footer()
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        // The screen carries its own header, so the nav bar is hidden for the times this is pushed
        // rather than presented — `EditAccountView` swaps itself for the paywall in place.
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .task { await store.loadProducts() }
        .alert(alertMessage, isPresented: $showAlert) {}
        .sheet(isPresented: $showTermsOfService) { LegalTextView(TermsOfService.markdownContent) }
        .sheet(isPresented: $showPrivacyPolicy) { LegalTextView(PrivacyPolicy.markdownContent) }
        .animation(.snappy, value: store.loadState)
        .animation(.snappy, value: selectedProductId)
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Bold Budget+")
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Spacer(minLength: 0)
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("PlusPaywallView.DismissButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Hero

    @ViewBuilder private func Hero() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: context.sfSymbol, size: 64, tint: .brandTeal)
            Text(context.title)
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.center)
            Text(context.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .paddingSmall)
    }

    // MARK: - Features

    private struct Feature: Identifiable {
        let sfSymbol: String
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
        var id: String { sfSymbol }
    }

    private var features: [Feature] {
        [
            .init(
                sfSymbol: "building.columns",
                title: "Unlimited accounts",
                detail: "Every bank, card, loan, and retirement account in one place."
            ),
            .init(
                sfSymbol: "chart.line.uptrend.xyaxis",
                title: "Net worth over time",
                detail: "The full history chart, not just today's number."
            ),
            .init(
                sfSymbol: "person.2",
                title: "Share a budget",
                detail: "Invite your partner or family. They don't need their own subscription."
            ),
            .init(
                sfSymbol: "square.stack.3d.up",
                title: "Unlimited budgets",
                detail: "Keep household, business, and side projects apart."
            ),
            .init(
                sfSymbol: "square.and.arrow.up",
                title: "Export to CSV",
                detail: "Every transaction, in a file you own."
            ),
            .init(
                sfSymbol: "hand.raised",
                title: "No ads",
                detail: "The whole app, uninterrupted."
            ),
        ]
    }

    @ViewBuilder private func FeatureList() -> some View {
        VStack(spacing: .padding) {
            ForEach(features) { feature in
                HStack(spacing: .padding) {
                    IconCircle(systemName: feature.sfSymbol, size: 40, tint: .brandTeal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appText)
                        Text(feature.detail)
                            .font(.caption)
                            .foregroundStyle(Color.appMutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: - Plans

    @ViewBuilder private func Plans() -> some View {
        switch store.loadState {
        case .loading:
            ProgressView()
                .tint(Color.brandTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .padding * 2)
        case .failed(let message):
            VStack(spacing: .paddingSmall) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.appMutedText)
                    .multilineTextAlignment(.center)
                Button("Try Again") {
                    Task { await store.loadProducts() }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandTeal)
            }
            .frame(maxWidth: .infinity)
            .card()
        case .loaded:
            VStack(spacing: .paddingSmall) {
                ForEach(store.products, id: \.id) { product in
                    PlanRow(product)
                }
            }
        }
    }

    @ViewBuilder private func PlanRow(_ product: Product) -> some View {
        let isSelected = product.id == selectedProductId

        Button {
            selectedProductId = product.id
        } label: {
            HStack(spacing: .padding) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.brandTeal : Color.appMutedText)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: .paddingSmall) {
                        Text(planTitle(for: product))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appText)
                        if let badge = planBadge(for: product) {
                            Chip(text: badge)
                        }
                    }
                    if let detail = planDetail(for: product) {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(Color.appMutedText)
                    }
                }
                Spacer(minLength: 0)
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(Color.appText)
            }
            .padding(.padding)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.appSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .strokeBorder(Color.brandTeal, lineWidth: isSelected ? .borderWidthMedium : 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("PlusPaywallView.Plan.\(product.id)")
    }

    private func planTitle(for product: Product) -> String {
        switch product.id {
        case BoldBudgetProduct.yearlyId: String(localized: "Yearly")
        case BoldBudgetProduct.monthlyId: String(localized: "Monthly")
        case BoldBudgetProduct.lifetimeId: String(localized: "Lifetime")
        default: product.displayName
        }
    }

    private func planBadge(for product: Product) -> String? {
        switch product.id {
        case BoldBudgetProduct.yearlyId:
            store.yearlySavingsPercent.map { String(localized: "Save \($0)%") }
        case BoldBudgetProduct.lifetimeId:
            String(localized: "One time")
        default:
            nil
        }
    }

    private func planDetail(for product: Product) -> String? {
        switch product.id {
        case BoldBudgetProduct.yearlyId:
            store.monthlyEquivalent(of: product).map { String(localized: "\($0) per month, billed yearly") }
        case BoldBudgetProduct.monthlyId:
            String(localized: "Billed monthly")
        case BoldBudgetProduct.lifetimeId:
            String(localized: "Pay once, keep it forever")
        default:
            nil
        }
    }

    // MARK: - Footer

    @ViewBuilder private func Footer() -> some View {
        VStack(spacing: .paddingSmall) {
            Button { buy() } label: {
                PrimaryButtonLabel(
                    title: callToActionTitle,
                    enabled: selectedProduct != nil && !store.isBusy,
                    background: .brandTeal,
                    foreground: .appBackground
                )
            }
            .disabled(selectedProduct == nil || store.isBusy)
            .accessibilityIdentifier("PlusPaywallView.PurchaseButton")

            if let renewalDisclosure {
                Text(renewalDisclosure)
                    .font(.caption2)
                    .foregroundStyle(Color.appMutedText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: .padding) {
                Button("Restore") { restore() }
                    .accessibilityIdentifier("PlusPaywallView.RestoreButton")
                Button("Terms") { showTermsOfService = true }
                Button("Privacy") { showPrivacyPolicy = true }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.brandTeal)
            .disabled(store.isBusy)
        }
        .padding()
        .background(Color.appBackground)
    }

    /// Apple requires the renewal terms next to the buy button for auto-renewing products. Nil until
    /// a product has actually loaded — quoting renewal terms with a blank price is worse than none.
    private var renewalDisclosure: String? {
        guard let product = selectedProduct else { return nil }

        guard product.id != BoldBudgetProduct.lifetimeId else {
            return String(localized: "A one-time purchase. No subscription, nothing to cancel.")
        }

        let trialNote = trialDescription.map { String(localized: "Free for \($0), then ") } ?? ""
        let period = product.id == BoldBudgetProduct.yearlyId
            ? String(localized: "year")
            : String(localized: "month")
        return String(localized: "\(trialNote)\(product.displayPrice) per \(period). Renews automatically until cancelled. Cancel any time in your Apple Account settings.")
    }
}

/// A plain scrolling wall of markdown, used for the Terms and Privacy sheets.
struct LegalTextView: View {

    @Environment(\.dismiss) private var dismiss

    private let markdownContent: String

    init(_ markdownContent: String) {
        self.markdownContent = markdownContent
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(LocalizedStringKey(markdownContent))
                    .font(.subheadline)
                    .foregroundStyle(Color.appText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.brandTeal)
                }
            }
        }
    }
}

#Preview {
    PlusPaywallView(context: .accounts, subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .none))
}
