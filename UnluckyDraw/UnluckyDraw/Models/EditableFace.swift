//
//  EditableFace.swift
//  UnluckyDraw
//
//  Created on 2025-06-18
//

import Foundation
import UIKit

struct EditableFace: Identifiable, Equatable {
    let id = UUID()
    var boundingBox: CGRect  // 실제 픽셀 좌표 (이미지 기준)
    var confidence: Float
    var isUserAdded: Bool = false  // 사용자가 수동으로 추가한 박스인지
    var croppedImage: UIImage?
    
    // 룰렛용 상태
    var isWinner: Bool = false
    var isHighlighted: Bool = false
    
    // 편집용 상태
    var isDragging: Bool = false
    var dragOffset: CGSize = .zero
    
    // DetectedFace로부터 생성하는 초기화
    init(from detectedFace: DetectedFace, imageSize: CGSize) {
        // Vision 좌표계를 실제 픽셀 좌표로 변환
        self.boundingBox = detectedFace.displayBoundingBox(for: imageSize)
        self.confidence = detectedFace.confidence
        self.isUserAdded = false
        self.croppedImage = detectedFace.croppedImage
    }
    
    // 새로운 박스 생성용 초기화
    init(boundingBox: CGRect, confidence: Float = 1.0, isUserAdded: Bool = true) {
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.isUserAdded = isUserAdded
    }
    
    // 중심점 계산
    var centerPoint: CGPoint {
        return CGPoint(x: boundingBox.midX, y: boundingBox.midY)
    }
    
    // 드래그 적용된 실제 위치
    var currentPosition: CGPoint {
        return CGPoint(
            x: centerPoint.x + dragOffset.width,
            y: centerPoint.y + dragOffset.height
        )
    }
    
    // 드래그 적용된 실제 박스
    var currentBoundingBox: CGRect {
        return CGRect(
            x: boundingBox.origin.x + dragOffset.width,
            y: boundingBox.origin.y + dragOffset.height,
            width: boundingBox.width,
            height: boundingBox.height
        )
    }
    
    // 드래그 완료 시 위치 적용
    mutating func applyDragOffset() {
        boundingBox.origin.x += dragOffset.width
        boundingBox.origin.y += dragOffset.height
        dragOffset = .zero
        isDragging = false
    }
    
    // 이미지 영역 내로 제한
    mutating func constrainToImage(size: CGSize) {
        let minX: CGFloat = 0
        let minY: CGFloat = 0
        let maxX = size.width - boundingBox.width
        let maxY = size.height - boundingBox.height
        
        boundingBox.origin.x = max(minX, min(maxX, boundingBox.origin.x))
        boundingBox.origin.y = max(minY, min(maxY, boundingBox.origin.y))
    }
    
    static func == (lhs: EditableFace, rhs: EditableFace) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 유틸리티 함수들

extension EditableFace {
    
    // 기존 박스들의 평균 크기 계산
    static func averageSize(from faces: [EditableFace]) -> CGSize {
        guard !faces.isEmpty else {
            return CGSize(width: 100, height: 100) // 기본 크기
        }
        
        let totalWidth = faces.reduce(0) { $0 + $1.boundingBox.width }
        let totalHeight = faces.reduce(0) { $0 + $1.boundingBox.height }
        
        return CGSize(
            width: totalWidth / CGFloat(faces.count),
            height: totalHeight / CGFloat(faces.count)
        )
    }
    
    // 빈 공간 찾아서 새 박스 위치 제안 (향상된 알고리즘)
    static func suggestPosition(for newSize: CGSize, in imageSize: CGSize, avoiding existingFaces: [EditableFace]) -> CGPoint {
        let padding: CGFloat = 30
        let minSpacing: CGFloat = 20  // 기존 박스와의 최소 간격
        
        // 1단계: 가장자리 우선 탐색 (얼굴이 보통 중앙에 모여있으므로)
        let edgePositions = generateEdgePositions(newSize: newSize, imageSize: imageSize, padding: padding)
        
        for position in edgePositions {
            let testRect = CGRect(origin: position, size: newSize)
            if !hasOverlap(testRect: testRect, with: existingFaces, minSpacing: minSpacing) {
                print("📍 Found edge position: \(position)")
                return position
            }
        }
        
        // 2단계: 그리드 방식으로 전체 영역 탐색
        let gridStep: CGFloat = min(newSize.width, newSize.height) / 2
        
        for y in stride(from: padding, to: imageSize.height - newSize.height - padding, by: gridStep) {
            for x in stride(from: padding, to: imageSize.width - newSize.width - padding, by: gridStep) {
                let testRect = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
                
                if !hasOverlap(testRect: testRect, with: existingFaces, minSpacing: minSpacing) {
                    print("📍 Found grid position: \(CGPoint(x: x, y: y))")
                    return CGPoint(x: x, y: y)
                }
            }
        }
        
        // 3단계: 중앙 배치 (겹치더라도)
        let centerPosition = CGPoint(
            x: (imageSize.width - newSize.width) / 2,
            y: (imageSize.height - newSize.height) / 2
        )
        
        print("⚠️ No free space found, placing at center: \(centerPosition)")
        return centerPosition
    }
    
    // 가장자리 위치들 생성
    private static func generateEdgePositions(newSize: CGSize, imageSize: CGSize, padding: CGFloat) -> [CGPoint] {
        var positions: [CGPoint] = []
        
        let stepSize: CGFloat = max(50, min(newSize.width, newSize.height))
        
        // 상단 가장자리
        for x in stride(from: padding, to: imageSize.width - newSize.width - padding, by: stepSize) {
            positions.append(CGPoint(x: x, y: padding))
        }
        
        // 하단 가장자리
        for x in stride(from: padding, to: imageSize.width - newSize.width - padding, by: stepSize) {
            positions.append(CGPoint(x: x, y: imageSize.height - newSize.height - padding))
        }
        
        // 좌측 가장자리
        for y in stride(from: padding, to: imageSize.height - newSize.height - padding, by: stepSize) {
            positions.append(CGPoint(x: padding, y: y))
        }
        
        // 우측 가장자리
        for y in stride(from: padding, to: imageSize.height - newSize.height - padding, by: stepSize) {
            positions.append(CGPoint(x: imageSize.width - newSize.width - padding, y: y))
        }
        
        return positions
    }
    
    // 겹침 검사 (개선된 버전)
    private static func hasOverlap(testRect: CGRect, with existingFaces: [EditableFace], minSpacing: CGFloat) -> Bool {
        for face in existingFaces {
            let existingRect = face.currentBoundingBox.insetBy(dx: -minSpacing, dy: -minSpacing)
            if testRect.intersects(existingRect) {
                return true
            }
        }
        return false
    }
}
