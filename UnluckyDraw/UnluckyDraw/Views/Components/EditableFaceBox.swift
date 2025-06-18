//
//  EditableFaceBox.swift
//  UnluckyDraw
//
//  Created on 2025-06-18
//

import SwiftUI

struct EditableFaceBox: View {
    let face: EditableFace
    let imageSize: CGSize
    let index: Int  // 얼굴 번호 표시용
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteButton = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragInBounds = true  // 🆕 드래그가 경계 내에 있는지
    @State private var showSnapGuides = false  // 🆕 스냅 가이드 표시
    
    // 🆕 스냅 설정
    private let snapThreshold: CGFloat = 15  // 스냅 임계값
    private let edgeSnapDistance: CGFloat = 30  // 가장자리 스냅 거리
    
    var body: some View {
        let currentBox = face.currentBoundingBox
        
        ZStack {
            // 🆕 스냅 가이드 라인들
            if showSnapGuides {
                SnapGuidesView(
                    imageSize: imageSize,
                    currentBox: currentBox,
                    snapThreshold: snapThreshold
                )
            }
            
            // Main Box
            Rectangle()
                .stroke(boxColor, lineWidth: boxLineWidth)
                .background(
                    Rectangle()
                        .fill(boxColor.opacity(face.isHighlighted ? 0.2 : (isDragInBounds ? 0.1 : 0.05)))
                )
                .frame(width: currentBox.width, height: currentBox.height)
                .position(
                    x: currentBox.midX,
                    y: currentBox.midY
                )
                .scaleEffect(face.isDragging ? 1.05 : (face.isHighlighted ? 1.02 : 1.0))
                .animation(.easeInOut(duration: 0.2), value: face.isDragging)
                .animation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true), value: face.isHighlighted)
                .overlay(
                    // 🆕 경계 벗어났을 때 경고 표시
                    Rectangle()
                        .stroke(Color.red.opacity(0.8), lineWidth: 3)
                        .frame(width: currentBox.width, height: currentBox.height)
                        .opacity(!isDragInBounds && face.isDragging ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: isDragInBounds)
                )
            
            // Face Number Badge
            Text("\(index + 1)")
                .font(.system(size: badgeSize, weight: .bold))
                .foregroundColor(.white)
                .frame(width: badgeSize + 8, height: badgeSize + 8)
                .background(
                    Circle()
                        .fill(badgeColor)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 1)
                )
                .position(
                    x: currentBox.minX + (badgeSize + 8) / 2 + 4,
                    y: currentBox.minY + (badgeSize + 8) / 2 + 4
                )
            
            // Delete Button (조건부 표시)
            if showDeleteButton {
                Button(action: {
                    HapticManager.impact(.light)
                    onDelete()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                        )
                }
                .position(
                    x: currentBox.maxX - 10,
                    y: currentBox.minY + 10
                )
                .scaleEffect(showDeleteButton ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: showDeleteButton)
            }
            
            // User Added Indicator (사용자 추가 박스 표시)
            if face.isUserAdded {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                    )
                    .position(
                        x: currentBox.maxX - 10,
                        y: currentBox.maxY - 10
                    )
            }
        }
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    if !face.isDragging {
                        HapticManager.selection()
                        showSnapGuides = true
                    }
                    
                    // 🆕 향상된 드래그 로직
                    let proposedOffset = value.translation
                    let constrainedOffset = constrainDragOffset(proposedOffset)
                    let snappedOffset = applySnapping(constrainedOffset)
                    
                    dragOffset = snappedOffset
                    onDragChanged(dragOffset)
                    
                    // 경계 검사
                    isDragInBounds = checkBounds(offset: dragOffset)
                    showDeleteButton = true
                }
                .onEnded { value in
                    // 🆕 드래그 종료 시 최종 스냅 및 제약 적용
                    let finalOffset = constrainDragOffset(dragOffset)
                    let finalSnappedOffset = applySnapping(finalOffset)
                    
                    // 경계 밖에 있으면 경고 했틱
                    if !checkBounds(offset: finalSnappedOffset) {
                        HapticManager.notification(.warning)
                    } else {
                        HapticManager.impact(.light)
                    }
                    
                    // 상태 리셋
                    dragOffset = .zero
                    showSnapGuides = false
                    isDragInBounds = true
                    
                    onDragEnded()
                    
                    // 삭제 버튼 숨기기
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showDeleteButton = false
                        }
                    }
                }
        )
        .onTapGesture {
            // 탭하면 삭제 버튼 토글
            HapticManager.impact(.light)
            withAnimation(.easeInOut(duration: 0.2)) {
                showDeleteButton.toggle()
            }
            
            if showDeleteButton {
                // 3초 후 자동으로 숨기기
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showDeleteButton = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var boxColor: Color {
        if face.isHighlighted {
            return .highlightYellow  // 하이라이트 색상
        } else if face.isDragging {
            return .primaryOrange
        } else if face.isUserAdded {
            return .blue
        } else {
            return .primaryRed
        }
    }
    
    private var boxLineWidth: CGFloat {
        if face.isHighlighted {
            return 4.0  // 하이라이트 시 두께 선
        } else {
            return face.isDragging ? 3.0 : 2.5
        }
    }
    
    private var badgeColor: Color {
        return face.isUserAdded ? .blue : .primaryRed
    }
    
    private var badgeSize: CGFloat {
        let minSize: CGFloat = 12
        let maxSize: CGFloat = 18
        let boxSize = min(face.boundingBox.width, face.boundingBox.height)
        
        // 박스 크기에 따라 배지 크기 조정 (50~150 픽셀 범위에서)
        let normalizedSize = (boxSize - 50) / (150 - 50)
        let clampedSize = max(0, min(1, normalizedSize))
        
        return minSize + (maxSize - minSize) * clampedSize
    }
    
    // MARK: - 🆕 드래그 제약 및 스냅 함수들
    
    /// 드래그 오프셋을 이미지 경계 내로 제한
    private func constrainDragOffset(_ offset: CGSize) -> CGSize {
        let currentBox = face.boundingBox
        let proposedBox = CGRect(
            x: currentBox.origin.x + offset.width,
            y: currentBox.origin.y + offset.height,
            width: currentBox.width,
            height: currentBox.height
        )
        
        let padding: CGFloat = 10
        let minX = padding
        let minY = padding
        let maxX = imageSize.width - currentBox.width - padding
        let maxY = imageSize.height - currentBox.height - padding
        
        let constrainedX = max(minX, min(maxX, proposedBox.origin.x))
        let constrainedY = max(minY, min(maxY, proposedBox.origin.y))
        
        return CGSize(
            width: constrainedX - currentBox.origin.x,
            height: constrainedY - currentBox.origin.y
        )
    }
    
    /// 스냅 적용 (가장자리 및 중앙선에 스냅)
    private func applySnapping(_ offset: CGSize) -> CGSize {
        let currentBox = face.boundingBox
        let proposedCenter = CGPoint(
            x: currentBox.midX + offset.width,
            y: currentBox.midY + offset.height
        )
        
        var snappedCenter = proposedCenter
        
        // 이미지 중앙선에 스냅
        let imageCenterX = imageSize.width / 2
        let imageCenterY = imageSize.height / 2
        
        if abs(proposedCenter.x - imageCenterX) < snapThreshold {
            snappedCenter.x = imageCenterX
            if !showSnapGuides { 
                HapticManager.selection()
            }
        }
        
        if abs(proposedCenter.y - imageCenterY) < snapThreshold {
            snappedCenter.y = imageCenterY
            if !showSnapGuides { 
                HapticManager.selection()
            }
        }
        
        // 가장자리에 스냅
        let edges = [
            edgeSnapDistance + currentBox.width / 2,  // 좌측
            imageSize.width - edgeSnapDistance - currentBox.width / 2,  // 우측
        ]
        
        for edge in edges {
            if abs(proposedCenter.x - edge) < snapThreshold {
                snappedCenter.x = edge
                if !showSnapGuides { 
                    HapticManager.selection()
                }
            }
        }
        
        let verticalEdges = [
            edgeSnapDistance + currentBox.height / 2,  // 상단
            imageSize.height - edgeSnapDistance - currentBox.height / 2,  // 하단
        ]
        
        for edge in verticalEdges {
            if abs(proposedCenter.y - edge) < snapThreshold {
                snappedCenter.y = edge
                if !showSnapGuides { 
                    HapticManager.selection()
                }
            }
        }
        
        return CGSize(
            width: snappedCenter.x - currentBox.midX,
            height: snappedCenter.y - currentBox.midY
        )
    }
    
    /// 경계 내에 있는지 확인
    private func checkBounds(offset: CGSize) -> Bool {
        let currentBox = face.boundingBox
        let proposedBox = CGRect(
            x: currentBox.origin.x + offset.width,
            y: currentBox.origin.y + offset.height,
            width: currentBox.width,
            height: currentBox.height
        )
        
        let imageBounds = CGRect(origin: .zero, size: imageSize)
        return imageBounds.contains(proposedBox)
    }
}

// MARK: - Preview Helper

struct EditableFaceBox_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFace = EditableFace(
            boundingBox: CGRect(x: 50, y: 50, width: 100, height: 120),
            confidence: 0.95,
            isUserAdded: false
        )
        
        ZStack {
            Color.gray.opacity(0.3)
            
            EditableFaceBox(
                face: sampleFace,
                imageSize: CGSize(width: 300, height: 400),
                index: 0,
                onDragChanged: { _ in },
                onDragEnded: { },
                onDelete: { }
            )
        }
        .frame(width: 300, height: 400)
        .previewLayout(.sizeThatFits)
    }
}
