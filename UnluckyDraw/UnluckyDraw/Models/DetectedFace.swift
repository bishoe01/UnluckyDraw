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
    
    // ⭐️ 디스플레이용 좌표 변환 (Vision → SwiftUI)
    func displayBoundingBox(for imageSize: CGSize) -> CGRect {
        // Vision 좌표계 (좌하단 원점) → SwiftUI 좌표계 (좌상단 원점)
        return CGRect(
            x: boundingBox.minX * imageSize.width,
            y: (1.0 - boundingBox.maxY) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
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
