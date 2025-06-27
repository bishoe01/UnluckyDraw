//
//  HapticManager.swift
//  UnluckyDraw
//
//  Created on 2025-06-18
//

import UIKit

struct HapticManager {
    
    /// 가벼운 터치 피드백 (버튼 터치, 선택 등)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// 성공/실패 피드백
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    /// 선택 변경 피드백 (드래그, 선택 변경 등)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
