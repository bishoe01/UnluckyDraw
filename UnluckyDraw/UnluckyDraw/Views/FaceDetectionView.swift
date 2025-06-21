//
//  FaceDetectionView.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import SwiftUI

struct FaceDetectionView: View {
    let image: UIImage
    let detectedFaces: [DetectedFace]
    let isProcessing: Bool
    let error: FaceDetectionController.FaceDetectionError?
    let autoStart: Bool
    let onNext: () -> Void
    
    @State private var autoStartTimer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            // 🎰 New arcade-style face counter!
            ArcadeFaceCounter(
                faceCount: detectedFaces.count,
                isProcessing: isProcessing,
                hasError: error != nil
            )
            .padding(.top, 20)
            
            // Auto-start notification (if needed)
            if autoStart && !detectedFaces.isEmpty && !isProcessing && error == nil {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundColor(.retroTeal)
                    
                    Text("Auto-starting in 2 seconds...")
                        .font(.caption)
                        .foregroundColor(.retroTeal)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.retroTeal.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.retroTeal.opacity(0.3), lineWidth: 1)
                        )
                )
                .onAppear {
                    checkAutoStart()
                }
            }
            
            // Image with Face Detection Overlay
            GeometryReader { geometry in
                ZStack {
                    // Background Image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                    
                    // Face Detection Overlays
                    if !isProcessing && error == nil {
                        ForEach(Array(detectedFaces.enumerated()), id: \.element.id) { index, face in
                            FaceOverlay(
                                face: face,
                                index: index,
                                imageSize: calculateImageSize(geometry: geometry)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                // Retake Button
                Button(action: {
                    // This would trigger retaking photo
                }) {
                    HStack {
                        Image(systemName: "camera.rotate.fill")
                        Text("Retake")
                    }
                    .foregroundColor(.adaptiveSecondaryLabel)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.adaptiveTertiaryBackground)
                    .cornerRadius(10)
                }
                
                // Continue Button
                if !detectedFaces.isEmpty && !isProcessing && error == nil {
                    Button(action: {
                        HapticManager.impact()
                        onNext()
                    }) {
                        HStack {
                            Text("Start Draw")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.retroTeal)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            if autoStart {
                // Wait 2 seconds after face detection completes and auto-start roulette
                startAutoStartTimer()
            }
        }
        .onDisappear {
            autoStartTimer?.invalidate()
        }
    }
    
    private func startAutoStartTimer() {
        autoStartTimer?.invalidate()
        
        // Auto-start when face detection is complete
        if !detectedFaces.isEmpty && !isProcessing && error == nil {
            autoStartTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                HapticManager.impact()
                onNext()
            }
        }
    }
    
    private func checkAutoStart() {
        if autoStart && !detectedFaces.isEmpty && !isProcessing && error == nil {
            startAutoStartTimer()
        }
    }
    
    private func calculateImageSize(geometry: GeometryProxy) -> CGSize {
        let maxWidth = geometry.size.width
        let maxHeight = geometry.size.height
        
        let imageAspectRatio = image.size.width / image.size.height
        let containerAspectRatio = maxWidth / maxHeight
        
        if imageAspectRatio > containerAspectRatio {
            // Image is wider - fit to width
            let width = maxWidth
            let height = width / imageAspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Image is taller - fit to height
            let height = maxHeight
            let width = height * imageAspectRatio
            return CGSize(width: width, height: height)
        }
    }
}

struct FaceOverlay: View {
    let face: DetectedFace
    let index: Int
    let imageSize: CGSize
    
    var body: some View {
        // ⭐️ Using new coordinate transformation system
        let displayBox = face.displayBoundingBox(for: imageSize)
        
        Rectangle()
            .stroke(Color.retroTeal.opacity(0.9), lineWidth: 2.5)
            .background(Color.retroTeal.opacity(0.1))
            .frame(width: displayBox.width, height: displayBox.height)
            .position(
                x: displayBox.midX,
                y: displayBox.midY
            )
            // Face number badge overlay - REMOVED
    }
}

#Preview {
    // This would need a sample image for preview
    FaceDetectionView(
        image: UIImage(systemName: "person.fill") ?? UIImage(),
        detectedFaces: [],
        isProcessing: false,
        error: nil,
        autoStart: false,
        onNext: {}
    )
}
