//
//  TouchWithLocation.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation
import SwiftUI

public struct TouchWithLocation: ViewModifier {
    
    @State private var location: CGPoint?
    private let coordinateSpace: CoordinateSpace
    private var perform: (CGPoint) -> Void
    private var onTouchEnded: (() -> Void)?

    init(
        coordinateSpace: CoordinateSpace = .local,
        perform: @escaping (CGPoint) -> Void,
        onTouchEnded: (() -> Void)? = nil
    ) {
        self.coordinateSpace = coordinateSpace
        self.perform = perform
        self.onTouchEnded = onTouchEnded
    }

    public func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: coordinateSpace)
                    .onChanged { value in
                        location = value.location
                        perform(location ?? .zero)
                    }
                    .onEnded { _ in
                        location = nil
                        onTouchEnded?()
                    }
//                    .simultaneously(with:
//                        TapGesture(count: 1)
//                            .onEnded {
//                                location = nil
//                                onTouchEnded?()
//                            }
//                    )
            )
    }
}

public extension View {
    func onTouchGesture(
        coordinateSpace: CoordinateSpace = .local,
        perform: @escaping (CGPoint) -> Void,
        onTouchEnded: (() -> Void)? = nil
    ) -> some View {
        modifier(TouchWithLocation(
            coordinateSpace: coordinateSpace,
            perform: perform,
            onTouchEnded: onTouchEnded
        ))
    }
}
