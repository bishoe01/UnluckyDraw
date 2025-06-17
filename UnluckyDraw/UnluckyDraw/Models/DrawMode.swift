//
//  DrawMode.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import Foundation

enum DrawMode: String, CaseIterable, Identifiable {
    case photo = "Photo Draw"
    case number = "Number Draw"
    case name = "Name Draw"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .photo:
            return "camera.fill"
        case .number:
            return "number.circle.fill"
        case .name:
            return "person.3.fill"
        }
    }
    
    var description: String {
        switch self {
        case .photo:
            return "Take a photo and pick unlucky face"
        case .number:
            return "Set number range and draw"
        case .name:
            return "Add names and pick one"
        }
    }
}
