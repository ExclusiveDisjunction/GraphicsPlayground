//
//  ColorContext.swift
//  FlowField
//
//  Created by Hollan Sellars on 12/18/25.
//

import CoreGraphics

extension ColorSchema {
    public var minHex: Int {
        Int(self.min.x * 255) << 16 | Int(self.min.y * 255) << 8 | Int(self.min.z * 255)
    }
    
    public var maxHex: Int {
        Int(self.max.x * 255) << 16 | Int(self.max.y * 255) << 8 | Int(self.max.z * 255)
    }
    
    public var minCGColor: CGColor {
        CGColor(red: CGFloat(self.min.x), green: CGFloat(self.min.y), blue: CGFloat(self.min.z), alpha: 1.0)
    }
    public var maxCGColor: CGColor {
        CGColor(red: CGFloat(self.max.x), green: CGFloat(self.max.y), blue: CGFloat(self.max.z), alpha: 1.0)
    }
}
