//
//  FaceReviewView.swift
//  UnluckyDraw
//
//  Created on 2025-06-18
//

import SwiftUI

struct FaceReviewView: View {
    let image: UIImage
    @ObservedObject var faceDetectionController: FaceDetectionController
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var imageSize: CGSize = .zero
    @State private var showingAddConfirmation = false
    @State private var isQuickAddMode = false  // 🆕 Quick add mode
    @State private var quickAddCount = 0
    
    private let maxQuickAdd = 5  // Maximum 5 quick additions
    
    var body: some View {
        VStack(spacing: 20) {
            // Header - Status display
            HeaderView(
                faceCount: faceDetectionController.editableFaces.count,
                isQuickAddMode: isQuickAddMode,
                quickAddCount: quickAddCount,
                maxQuickAdd: maxQuickAdd,
                onAddFace: addNewFace,
                onToggleQuickAdd: toggleQuickAddMode,
                onBack: onBack
            )
            
            // Main Content - Image and editable face boxes
            GeometryReader { geometry in
                ZStack {
                    // Background Image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        .onAppear {
                            updateImageSizeIfNeeded(geometry: geometry)
                        }
                        .onChange(of: geometry.size) { _, _ in
                            updateImageSizeIfNeeded(geometry: geometry)
                        }
                    
                    // Editable Face Boxes
                    if imageSize != .zero {
                        let calculatedImageSize = calculateImageSize(geometry: geometry)
                        let offsetX = (geometry.size.width - calculatedImageSize.width) / 2
                        let offsetY = (geometry.size.height - calculatedImageSize.height) / 2
                        
                        ForEach(Array(faceDetectionController.editableFaces.enumerated()), id: \.element.id) { index, face in
                            EditableFaceBox(
                                face: face,
                                imageSize: calculatedImageSize,
                                index: index,  // Pass face number
                                offsetX: offsetX,  // ⭐️ Add offset
                                offsetY: offsetY,  // ⭐️ Add offset
                                onDragChanged: { dragOffset in
                                    faceDetectionController.updateFacePosition(
                                        id: face.id,
                                        dragOffset: dragOffset
                                    )
                                },
                                onDragEnded: {
                                    faceDetectionController.finalizeFacePosition(id: face.id)
                                },
                                onDelete: {
                                    deleteFace(face)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Bottom Actions
            BottomActionsView(
                faceCount: faceDetectionController.editableFaces.count,
                onStart: startRoulette,
                onAddFace: addNewFace
            )
        }
        .onAppear {
            setupReviewMode()
        }
        .alert("Add New Person", isPresented: $showingAddConfirmation) {
            Button("Add") {
                faceDetectionController.addNewFace()
                HapticManager.notification(.success)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Add a new face box for someone who wasn't detected automatically.")
        }
    }
    
    private func calculateImageSize(geometry: GeometryProxy) -> CGSize {
        let maxWidth = geometry.size.width
        let maxHeight = geometry.size.height
        
        let imageAspectRatio = image.size.width / image.size.height
        let containerAspectRatio = maxWidth / maxHeight
        
        let newImageSize: CGSize
        if imageAspectRatio > containerAspectRatio {
            let width = maxWidth
            let height = width / imageAspectRatio
            newImageSize = CGSize(width: width, height: height)
        } else {
            let height = maxHeight
            let width = height * imageAspectRatio
            newImageSize = CGSize(width: width, height: height)
        }
        
        return newImageSize
    }
    
    private func updateImageSizeIfNeeded(geometry: GeometryProxy) {
        let newImageSize = calculateImageSize(geometry: geometry)
        
        // Update only when image size has changed
        if imageSize != newImageSize {
            imageSize = newImageSize
            
            // Also pass image size information to FaceDetectionController
            if faceDetectionController.currentImageSize != newImageSize {
                faceDetectionController.convertToEditableFaces(imageSize: newImageSize)
            }
        }
    }
    
    private func setupReviewMode() {
        print("🔍 Setting up face review mode")
        
        // convertToEditableFaces is automatically called when image size is set
        if imageSize != .zero {
            faceDetectionController.convertToEditableFaces(imageSize: imageSize)
        }
    }
    
    private func addNewFace() {
        HapticManager.impact(.medium)
        
        if isQuickAddMode {
            // Quick add mode: add immediately
            faceDetectionController.addNewFace()
            quickAddCount += 1
            
            // Turn off mode when maximum count is reached
            if quickAddCount >= maxQuickAdd {
                toggleQuickAddMode()
            }
        } else {
            // Normal mode: confirmation dialog
            showingAddConfirmation = true
        }
    }
    
    private func toggleQuickAddMode() {
        HapticManager.impact(.heavy)
        isQuickAddMode.toggle()
        
        if isQuickAddMode {
            quickAddCount = 0
            print("🚀 Quick add mode activated")
        } else {
            print("🚀 Quick add mode deactivated")
        }
    }
    
    private func deleteFace(_ face: EditableFace) {
        HapticManager.impact(.medium)
        faceDetectionController.removeFace(withId: face.id)
    }
    
    private func startRoulette() {
        guard !faceDetectionController.editableFaces.isEmpty else {
            print("⚠️ Cannot start roulette: no faces available")
            return
        }
        
        HapticManager.impact(.heavy)
        print("🎰 Starting roulette with \(faceDetectionController.editableFaces.count) faces")
        onNext()
    }
}

// MARK: - Header View

struct HeaderView: View {
    let faceCount: Int
    let isQuickAddMode: Bool
    let quickAddCount: Int
    let maxQuickAdd: Int
    let onAddFace: () -> Void
    let onToggleQuickAdd: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Top Row - Navigation and Quick Mode Toggle
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.darkGray)
                }
                
                Spacer()
                
                // Quick Add Toggle
                Button(action: onToggleQuickAdd) {
                    HStack(spacing: 6) {
                        Image(systemName: isQuickAddMode ? "bolt.fill" : "bolt")
                            .font(.caption)
                        Text(isQuickAddMode ? "Quick Add ON" : "Quick Add")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(isQuickAddMode ? .white : .retroTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isQuickAddMode ? Color.retroTeal : Color.clear)
                            .stroke(Color.retroTeal, lineWidth: 1)
                    )
                    .scaleEffect(isQuickAddMode ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isQuickAddMode)
                }
            }
            
            // Status Section
            VStack(spacing: 8) {
                // Main Status
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundColor(.retroTeal)
                    
                    VStack(spacing: 4) {
                        Text("\(faceCount) People")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.darkGray)
                        
                        Text(statusDescription)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Add Button
                    Button(action: onAddFace) {
                        Image(systemName: isQuickAddMode ? "plus.circle.fill" : "plus.circle")
                            .font(.title)
                            .foregroundColor(.retroTeal)
                            .scaleEffect(isQuickAddMode ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isQuickAddMode)
                    }
                }
                
                // Quick Add Progress
                if isQuickAddMode {
                    HStack {
                        Text("Quick Add Progress:")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(quickAddCount)/\(maxQuickAdd)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.retroTeal)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.3), value: isQuickAddMode)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var statusDescription: String {
        if isQuickAddMode {
            return "Tap + to quickly add people (\(maxQuickAdd - quickAddCount) left)"
        } else {
            return "Review and adjust face detection"
        }
    }
}

// MARK: - Bottom Actions View

struct BottomActionsView: View {
    let faceCount: Int
    let onStart: () -> Void
    let onAddFace: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Instructions
            Text("• Tap + to add missing people\\n• Drag boxes to adjust position\\n• Tap × to remove incorrect detections")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // Action Buttons
            HStack(spacing: 16) {
                // Add Face Button
                Button(action: onAddFace) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.headline)
                        Text("Add Person")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.retroTeal)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.retroTeal, lineWidth: 2)
                    )
                }
                
                // Start Button
                Button(action: onStart) {
                    HStack(spacing: 8) {
                        Text("Start Draw")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "play.fill")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.retroTeal)
                    )
                }
                .disabled(faceCount == 0)
                .opacity(faceCount == 0 ? 0.5 : 1.0)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
}

#Preview {
    FaceReviewView(
        image: UIImage(systemName: "person.fill") ?? UIImage(),
        faceDetectionController: FaceDetectionController(),
        onNext: {},
        onBack: {}
    )
}
