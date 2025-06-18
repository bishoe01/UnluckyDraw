//
//  SnapGuidesView.swift
//  UnluckyDraw
//
//  Created on 2025-06-18
//

import SwiftUI

struct SnapGuidesView: View {
    let imageSize: CGSize
    let currentBox: CGRect
    let snapThreshold: CGFloat
    
    private let lineOpacity: Double = 0.4
    private let lineWidth: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 중앙 세로선
            if shouldShowVerticalCenterGuide {
                Rectangle()
                    .fill(Color.blue.opacity(lineOpacity))
                    .frame(width: lineWidth, height: imageSize.height)
                    .position(x: imageSize.width / 2, y: imageSize.height / 2)
            }
            
            // 중앙 가로선
            if shouldShowHorizontalCenterGuide {
                Rectangle()
                    .fill(Color.blue.opacity(lineOpacity))
                    .frame(width: imageSize.width, height: lineWidth)
                    .position(x: imageSize.width / 2, y: imageSize.height / 2)
            }
            
            // 가장자리 가이드 라인들
            ForEach(edgeGuides, id: \.id) { guide in
                Rectangle()
                    .fill(Color.orange.opacity(lineOpacity))
                    .frame(width: guide.isVertical ? lineWidth : imageSize.width,
                           height: guide.isVertical ? imageSize.height : lineWidth)
                    .position(x: guide.position.x, y: guide.position.y)
            }
        }
        .allowsHitTesting(false) // 터치 이벤트 통과
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowVerticalCenterGuide: Bool {
        let centerX = imageSize.width / 2
        return abs(currentBox.midX - centerX) < snapThreshold
    }
    
    private var shouldShowHorizontalCenterGuide: Bool {
        let centerY = imageSize.height / 2
        return abs(currentBox.midY - centerY) < snapThreshold
    }
    
    private var edgeGuides: [EdgeGuide] {
        var guides: [EdgeGuide] = []
        let edgeDistance: CGFloat = 30
        
        // 세로 가장자리 가이드들
        let leftEdge = edgeDistance + currentBox.width / 2
        let rightEdge = imageSize.width - edgeDistance - currentBox.width / 2
        
        if abs(currentBox.midX - leftEdge) < snapThreshold {
            guides.append(EdgeGuide(
                position: CGPoint(x: leftEdge, y: imageSize.height / 2),
                isVertical: true
            ))
        }
        
        if abs(currentBox.midX - rightEdge) < snapThreshold {
            guides.append(EdgeGuide(
                position: CGPoint(x: rightEdge, y: imageSize.height / 2),
                isVertical: true
            ))
        }
        
        // 가로 가장자리 가이드들
        let topEdge = edgeDistance + currentBox.height / 2
        let bottomEdge = imageSize.height - edgeDistance - currentBox.height / 2
        
        if abs(currentBox.midY - topEdge) < snapThreshold {
            guides.append(EdgeGuide(
                position: CGPoint(x: imageSize.width / 2, y: topEdge),
                isVertical: false
            ))
        }
        
        if abs(currentBox.midY - bottomEdge) < snapThreshold {
            guides.append(EdgeGuide(
                position: CGPoint(x: imageSize.width / 2, y: bottomEdge),
                isVertical: false
            ))
        }
        
        return guides
    }
}

// MARK: - Helper Types

private struct EdgeGuide {
    let id = UUID()
    let position: CGPoint
    let isVertical: Bool
}

// MARK: - Preview

struct SnapGuidesView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3)
            
            SnapGuidesView(
                imageSize: CGSize(width: 300, height: 400),
                currentBox: CGRect(x: 140, y: 190, width: 60, height: 80),
                snapThreshold: 15
            )
        }
        .frame(width: 300, height: 400)
        .previewLayout(.sizeThatFits)
    }
}
