//
//  PopupNotificationContainerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/11/25.
//

import SwiftUI
import SwinjectAutoregistration
import Combine

struct PopupNotificationContainerView: View {
    
    @StateObject var model: PopupNotificationContainerViewModel
    @State private var notifications: [PopupNotification] = []
    
    init() {
        self.init(
            popupNotificationCenter: iocContainer~>PopupNotificationCenter.self
        )
    }
    
    init (
        popupNotificationCenter: PopupNotificationCenter
    ) {
        self._model = .init(wrappedValue: .init(popupNotificationCenter: popupNotificationCenter))
    }
    
    var body: some View {
        VStack {
            Spacer()
            ForEach(notifications) { notification in
                PopupNotificationView(notification)
            }
        }
        .animation(.snappy, value: notifications)
        .onChange(of: model.notifications) { notifications = $1 }
    }
    
    @ViewBuilder private func PopupNotificationView(_ notification: PopupNotification) -> some View {
        HStack {
            if let sfSymbol = notification.sfSymbol {
                Image(systemName: sfSymbol)
                    .frame(
                        width: .popupNotificationImageSize,
                        height: .popupNotificationImageSize
                    )
                    .foregroundStyle(Color.text)
                    .background(
                        Color.text.opacity(.opacityButtonBackground),
                        in: RoundedRectangle(cornerRadius: .cornerRadiusMedium)
                    )
            }
            VStack(alignment: .leading) {
                Text(notification.title)
                    .font(.body)
                    .lineLimit(1)
                if let subtitle = notification.subtitle {
                    Text(subtitle)
                        .lineLimit(1)
                        .font(.subheadline.bold())
                        .opacity(0.6)
                }
            }
            Spacer()
        }
        .foregroundStyle(Color.text)
        .padding(.horizontal, .paddingHorizontalButtonXSmall)
        .padding(.vertical, .paddingVerticalButtonXSmall)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                .fill(Color.background)
                .shadow(color: Color.text.opacity(0.2), radius: 2)
        }
        .padding(.horizontal)
        .transition(.asymmetric(insertion: .push(from: .bottom), removal: .opacity))
        .onTapGesture { model.dismiss(notification: notification) }
    }
}

#Preview {
    let notificationCenter = PopupNotificationCenter()
    
    ZStack {
        Rectangle()
            .fill(Color.background)
            .ignoresSafeArea()
        Button("Send Notification") {
            notificationCenter.genericNotification(
                "This is a test",
                subtitle: "This is a test message",
                sfSymbol: "globe"
            )
        }
        PopupNotificationContainerView()
    }
}
