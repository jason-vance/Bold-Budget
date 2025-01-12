//
//  PopupNotificationContainerViewModel.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/11/25.
//

import Foundation
import Combine

@MainActor
class PopupNotificationContainerViewModel: ObservableObject {
    
    @Published var notifications: [PopupNotification] = []
    
    private let popupNotificationCenter: PopupNotificationCenter
    
    private var subs: Set<AnyCancellable> = []
    
    init(popupNotificationCenter: PopupNotificationCenter) {
        self.popupNotificationCenter = popupNotificationCenter
        
        popupNotificationCenter.notificationPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: show(notification:))
            .store(in: &subs)
        
        popupNotificationCenter.notificationPublisher
            .delay(for: .seconds(5), scheduler: RunLoop.main)
            .sink(receiveValue: dismiss(notification:))
            .store(in: &subs)
    }
    
    func show(notification: PopupNotification) {
        notifications.append(notification)
    }
    
    func dismiss(notification: PopupNotification) {
        guard let index = notifications.firstIndex(of: notification) else { return }
        notifications.remove(at: index)
    }
}
