//
//  PopupNotificationCenter.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/11/25.
//

import Foundation
import SwinjectAutoregistration
import Combine

class PopupNotificationCenter {
    
    @Published private var notification: PopupNotification? = nil
    public var notificationPublisher: AnyPublisher<PopupNotification,Never> {
        $notification
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    func genericNotification(_ text: String, subtitle: String? = nil, sfSymbol: String? = nil) {
        notification = .init(
            title: text,
            subtitle: subtitle,
            sfSymbol: sfSymbol
        )
    }
    
    func errorNotification(_ text: String, error: Error) {
        genericNotification(
            text,
            subtitle: error.localizedDescription,
            sfSymbol: "exclamationmark.triangle.fill"
        )
    }
}
