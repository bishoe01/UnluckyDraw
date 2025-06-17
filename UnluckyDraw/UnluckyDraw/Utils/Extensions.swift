//
//  Extensions.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import SwiftUI
import UIKit

// MARK: - Color Extensions
extension Color {
    static let primaryRed = Color(red: 0.96, green: 0.26, blue: 0.21)
    static let primaryOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let darkGray = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let lightGray = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    // 룰렛 하이라이트 색상
    static let highlightYellow = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let winnerGreen = Color(red: 0.0, green: 0.78, blue: 0.32)
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    func buttonStyle(backgroundColor: Color = .primaryRed, foregroundColor: Color = .white) -> some View {
        self
            .foregroundColor(foregroundColor)
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(color: backgroundColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Haptic Feedback Helper
struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}
