//
//  GeometryUtils.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation
import CoreGraphics

func angleBetween(center: CGPoint, point: CGPoint) -> CGFloat {
    let dx = point.x - center.x
    let dy = point.y - center.y
    
    // Calculate the angle using atan2
    let radians = atan2(dy, dx)
    
    // Convert radians to degrees if needed
    let degrees = radians * 180 / .pi
    
    return degrees >= 0 ? degrees : degrees + 360
}
