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
    let index: Int  // For displaying face number
    let offsetX: CGFloat  // ⭐️ Add image offset
    let offsetY: CGFloat  // ⭐️ Add image offset
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteButton = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragInBounds = true  // 🆕 Whether drag is within bounds
    @State private var showSnapGuides = false  // 🆕 Show snap guides
    
    // 🆕 Snap settings
    private let snapThreshold: CGFloat = 15  // Snap threshold
    private let edgeSnapDistance: CGFloat = 30  // Edge snap distance
    
    var body: some View {
        let currentBox = face.currentBoundingBox
        
        ZStack {
            // 🆕 Snap guide lines
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
                    x: currentBox.midX + offsetX,
                    y: currentBox.midY + offsetY
                )
                .scaleEffect(face.isDragging ? 1.05 : (face.isHighlighted ? 1.02 : 1.0))
                .animation(.easeInOut(duration: 0.2), value: face.isDragging)
                .animation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true), value: face.isHighlighted)
                .overlay(
                    // 🆕 Warning display when out of bounds
                    Rectangle()
                        .stroke(Color.unluckyRed.opacity(0.8), lineWidth: 3)
                        .frame(width: currentBox.width, height: currentBox.height)
                        .opacity(!isDragInBounds && face.isDragging ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: isDragInBounds)
                )
            
            // Face Number Badge - REMOVED
            
            // Delete Button (conditional display)
            if showDeleteButton {
                Button(action: {
                    HapticManager.impact(.light)
                    onDelete()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.unluckyRed)
                        .background(
                            Circle()
                                .fill(Color.adaptiveBackground)
                                .frame(width: 18, height: 18)
                        )
                }
                .position(
                    x: currentBox.maxX - 10 + offsetX,
                    y: currentBox.minY + 10 + offsetY
                )
                .scaleEffect(showDeleteButton ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: showDeleteButton)
            }
            
            // User Added Indicator (user-added box display) - removed
            // Plus icon not displayed
        }
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    if !face.isDragging {
                        HapticManager.selection()
                        showSnapGuides = true
                    }
                    
                    // 🆕 Enhanced drag logic
                    let proposedOffset = value.translation
                    let constrainedOffset = constrainDragOffset(proposedOffset)
                    let snappedOffset = applySnapping(constrainedOffset)
                    
                    dragOffset = snappedOffset
                    onDragChanged(dragOffset)
                    
                    // Boundary check
                    isDragInBounds = checkBounds(offset: dragOffset)
                    showDeleteButton = true
                }
                .onEnded { value in
                    // 🆕 Apply final snap and constraints when drag ends
                    let finalOffset = constrainDragOffset(dragOffset)
                    let finalSnappedOffset = applySnapping(finalOffset)
                    
                    // Warning haptic if outside boundary
                    if !checkBounds(offset: finalSnappedOffset) {
                        HapticManager.notification(.warning)
                    } else {
                        HapticManager.impact(.light)
                    }
                    
                    // Reset state
                    dragOffset = .zero
                    showSnapGuides = false
                    isDragInBounds = true
                    
                    onDragEnded()
                    
                    // Hide delete button
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showDeleteButton = false
                        }
                    }
                }
        )
        .onTapGesture {
            // Tap to toggle delete button
            HapticManager.impact(.light)
            withAnimation(.easeInOut(duration: 0.2)) {
                showDeleteButton.toggle()
            }
            
            if showDeleteButton {
                // Automatically hide after 3 seconds
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
            return .highlightYellow  // Highlight color
        } else if face.isDragging {
            return .retroMint
        } else if face.isUserAdded {
            return .retroPurple
        } else {
            return .retroTeal
        }
    }
    
    private var boxLineWidth: CGFloat {
        if face.isHighlighted {
            return 4.0  // Thick line when highlighted
        } else {
            return face.isDragging ? 3.0 : 2.5
        }
    }
    
    // Badge color function - REMOVED (no longer needed)
    
    // Badge size function - REMOVED (no longer needed)
    
    // MARK: - 🆕 Drag constraint and snap functions
    
    /// Constrain drag offset within image boundaries
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
    
    /// Apply snapping (snap to edges and center lines)
    private func applySnapping(_ offset: CGSize) -> CGSize {
        let currentBox = face.boundingBox
        let proposedCenter = CGPoint(
            x: currentBox.midX + offset.width,
            y: currentBox.midY + offset.height
        )
        
        var snappedCenter = proposedCenter
        
        // Snap to image center lines
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
        
        // Snap to edges
        let edges = [
            edgeSnapDistance + currentBox.width / 2,  // Left
            imageSize.width - edgeSnapDistance - currentBox.width / 2,  // Right
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
            edgeSnapDistance + currentBox.height / 2,  // Top
            imageSize.height - edgeSnapDistance - currentBox.height / 2,  // Bottom
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
    
    /// Check if within boundaries
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
                offsetX: 0,  // ⭐️ Add offset
                offsetY: 0,  // ⭐️ Add offset
                onDragChanged: { _ in },
                onDragEnded: { },
                onDelete: { }
            )
        }
        .frame(width: 300, height: 400)
        .previewLayout(.sizeThatFits)
    }
}
