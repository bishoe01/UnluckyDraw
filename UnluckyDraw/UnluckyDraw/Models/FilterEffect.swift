//
//  FilterEffect.swift
//  UnluckyDraw
//
//  Created on 2025-06-27
//

import Foundation
import UIKit

enum FilterEffect: String, CaseIterable, Identifiable {
    case death = "death"
    case whirlpool = "whirlpool"
    case angel = "angel"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .death:
            return "💀 Death Mode"
        case .whirlpool:
            return "🌀 Whirlpool Mode"  
        case .angel:
            return "😇 Angel Mode"
        }
    }
    
    var description: String {
        switch self {
        case .death:
            return "Dark, dramatic death penalty"
        case .whirlpool:
            return "Face gets sucked into a whirlpool"
        case .angel:
            return "Blessed with angelic glow (for treats!)"
        }
    }
    
    var icon: String {
        switch self {
        case .death:
            return "skull.fill"
        case .whirlpool:
            return "tornado"
        case .angel:
            return "heart.circle.fill"
        }
    }
    
    var color: UIColor {
        switch self {
        case .death:
            return .systemRed
        case .whirlpool:
            return .systemTeal
        case .angel:
            return .systemYellow
        }
    }
}