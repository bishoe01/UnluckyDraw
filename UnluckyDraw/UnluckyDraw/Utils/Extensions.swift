//
//  Extensions.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import SwiftUI
import UIKit

extension Color {
    // MARK: - 기존 색상들 (호환성 유지)
    static let primaryRed = Color(red: 0.96, green: 0.26, blue: 0.21)
    static let primaryOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let darkGray = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let lightGray = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    // MARK: - 🌌 다크모드 대응 색상 시스템
    
    // 적응형 배경 색상
    static var adaptiveBackground: Color {
        Color(UIColor.systemBackground)
    }
    
    static var adaptiveSecondaryBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    static var adaptiveTertiaryBackground: Color {
        Color(UIColor.tertiarySystemBackground)
    }
    
    // 적응형 텍스트 색상
    static var adaptiveLabel: Color {
        Color(UIColor.label)
    }
    
    static var adaptiveSecondaryLabel: Color {
        Color(UIColor.secondaryLabel)
    }
    
    static var adaptiveTertiaryLabel: Color {
        Color(UIColor.tertiaryLabel)
    }
    
    // 적응형 경계선 색상
    static var adaptiveSeparator: Color {
        Color(UIColor.separator)
    }
    
    // 🎮 레트로 게임 컬러 팔레트 (다크모드 대응)
    static var retroTeal: Color {
        Color(light: Color(red: 0.0, green: 0.8, blue: 0.8),
              dark: Color(red: 0.2, green: 0.9, blue: 0.9))
    }
    
    static var retroPurple: Color {
        Color(light: Color(red: 0.6, green: 0.4, blue: 0.9),
              dark: Color(red: 0.7, green: 0.5, blue: 1.0))
    }
    
    static var retroPink: Color {
        Color(light: Color(red: 1.0, green: 0.4, blue: 0.7),
              dark: Color(red: 1.0, green: 0.5, blue: 0.8))
    }
    
    static var retroMint: Color {
        Color(light: Color(red: 0.2, green: 0.9, blue: 0.7),
              dark: Color(red: 0.3, green: 1.0, blue: 0.8))
    }
    
    static var retroNavy: Color {
        Color(light: Color(red: 0.1, green: 0.15, blue: 0.3),
              dark: Color(red: 0.25, green: 0.3, blue: 0.5))
    }
    
    static var retroIndigo: Color {
        Color(light: Color(red: 0.3, green: 0.2, blue: 0.6),
              dark: Color(red: 0.4, green: 0.3, blue: 0.7))
    }
    
    static var retroCharcoal: Color {
        Color(light: Color(red: 0.2, green: 0.2, blue: 0.3),
              dark: Color(red: 0.15, green: 0.15, blue: 0.25))
    }
    
    // 다크 톤 (배경용)
    static var retroDarkTeal: Color {
        Color(light: Color(red: 0.0, green: 0.5, blue: 0.5),
              dark: Color(red: 0.1, green: 0.6, blue: 0.6))
    }
    
    static var retroDarkPurple: Color {
        Color(light: Color(red: 0.4, green: 0.2, blue: 0.7),
              dark: Color(red: 0.5, green: 0.3, blue: 0.8))
    }
    
    // 경고 및 상태 색상 (다크모드 대응)
    static var unluckyRed: Color {
        Color(light: Color(red: 0.9, green: 0.2, blue: 0.2),
              dark: Color(red: 1.0, green: 0.3, blue: 0.3))
    }
    
    static var unluckyOrange: Color {
        Color(light: Color(red: 1.0, green: 0.4, blue: 0.0),
              dark: Color(red: 1.0, green: 0.5, blue: 0.1))
    }
    
    static var unluckyDarkRed: Color {
        Color(light: Color(red: 0.7, green: 0.1, blue: 0.1),
              dark: Color(red: 0.8, green: 0.2, blue: 0.2))
    }
    
    static var warningYellow: Color {
        Color(light: Color(red: 1.0, green: 0.8, blue: 0.0),
              dark: Color(red: 1.0, green: 0.85, blue: 0.1))
    }
    
    static var highlightYellow: Color {
        Color(light: Color(red: 1.0, green: 0.84, blue: 0.0),
              dark: Color(red: 1.0, green: 0.88, blue: 0.2))
    }
    
    static var winnerGreen: Color {
        Color(light: Color(red: 0.0, green: 0.78, blue: 0.32),
              dark: Color(red: 0.1, green: 0.85, blue: 0.4))
    }
    
    // MARK: - 🎮 커스텀 색상 이니셜라이저
    
    /// 라이트/다크 모드에 따라 다른 색상을 반환하는 이니셜라이저
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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
