//
//  Extensions.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import SwiftUI
import UIKit

extension Color {
    // 기존 색상들 (호환성 유지)
    static let primaryRed = Color(red: 0.96, green: 0.26, blue: 0.21)
    static let primaryOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let darkGray = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let lightGray = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    // 🕹️ 레트로 게임 컬러 팔레트
    static let retroTeal = Color(red: 0.0, green: 0.8, blue: 0.8)           // 시안 청록
    static let retroPurple = Color(red: 0.6, green: 0.4, blue: 0.9)         // 네온 보라
    static let retroPink = Color(red: 1.0, green: 0.4, blue: 0.7)           // 소프트 핑크
    static let retroNavy = Color(red: 0.1, green: 0.15, blue: 0.3)          // 진한 네이비
    static let retroIndigo = Color(red: 0.3, green: 0.2, blue: 0.6)         // 깊은 인디고
    static let retroMint = Color(red: 0.2, green: 0.9, blue: 0.7)           // 민트 그린
    
    // 다크 톤 (배경용)
    static let retroDarkTeal = Color(red: 0.0, green: 0.5, blue: 0.5)
    static let retroDarkPurple = Color(red: 0.4, green: 0.2, blue: 0.7)
    static let retroCharcoal = Color(red: 0.2, green: 0.2, blue: 0.3)

    static let unluckyRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let unluckyOrange = Color(red: 1.0, green: 0.4, blue: 0.0)
    static let unluckyDarkRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    static let warningYellow = Color(red: 1.0, green: 0.8, blue: 0.0)

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

enum HapticManager {
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
