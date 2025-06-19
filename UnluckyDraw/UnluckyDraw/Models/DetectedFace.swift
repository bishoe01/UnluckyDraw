//
//  DetectedFace.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import Foundation
import Vision
import UIKit

struct DetectedFace: Identifiable, Equatable {
    let id = UUID()
    let boundingBox: CGRect  // Vision Framework 원본 좌표 (0~1 정규화, 좌하단 원점)
    let confidence: Float
    var isWinner: Bool = false
    
    // 화면에 실제로 표시되는 사각형 좌표 (픽셀 단위)
    var displayRect: CGRect?
    
    // ⭐️ 미리 크롭된 얼굴 이미지 (이게 핵심!)
    var croppedImage: UIImage?
    
    // 얼굴 영역의 중심점 (Vision 좌표계)
    var centerPoint: CGPoint {
        return CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )
    }
    
    // 룰렛 효과를 위한 선택 상태
    var isHighlighted: Bool = false
    
    // ⭐️ 디스플레이용 좌표 변환 (Vision → SwiftUI) - 완전히 수정된 버전
    func displayBoundingBox(for imageSize: CGSize) -> CGRect {
        // Vision 좌표계에서는 Y=0이 이미지 하단, Y=1이 상단
        // SwiftUI에서는 Y=0이 이미지 상단, Y=height가 하단
        
        let visionX = boundingBox.origin.x      // Vision X (왼쪽 끝)
        let visionY = boundingBox.origin.y      // Vision Y (아래쪽 끝)
        let visionWidth = boundingBox.width
        let visionHeight = boundingBox.height
        
        // SwiftUI 좌표로 변환
        let swiftUIX = visionX * imageSize.width
        let swiftUIY = (1.0 - visionY - visionHeight) * imageSize.height  // Y축 변환
        let swiftUIWidth = visionWidth * imageSize.width
        let swiftUIHeight = visionHeight * imageSize.height
        
        let convertedBox = CGRect(
            x: swiftUIX,
            y: swiftUIY,
            width: swiftUIWidth,
            height: swiftUIHeight
        )
        
        print("📊 Face displayBoundingBox conversion (FIXED):")
        print("  Vision box: \(boundingBox)")
        print("  Vision bottom-left: (\(visionX), \(visionY))")
        print("  Vision top-right: (\(visionX + visionWidth), \(visionY + visionHeight))")
        print("  SwiftUI top-left: (\(swiftUIX), \(swiftUIY))")
        print("  Image size: \(imageSize)")
        print("  Final box: \(convertedBox)")
        
        return convertedBox
    }
    
    static func == (lhs: DetectedFace, rhs: DetectedFace) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Drawing Result
struct DrawResult {
    let mode: DrawMode
    let winner: DetectedFace?
    let totalParticipants: Int
    let timestamp: Date
    
    init(mode: DrawMode, winner: DetectedFace? = nil, totalParticipants: Int) {
        self.mode = mode
        self.winner = winner
        self.totalParticipants = totalParticipants
        self.timestamp = Date()
    }
}
