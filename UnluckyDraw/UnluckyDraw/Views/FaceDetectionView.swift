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
            // Status Header
            VStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Detecting faces...")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else if let error = error {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text(error.localizedDescription)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.winnerGreen)
                    Text("Found \(detectedFaces.count) face\(detectedFaces.count == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(.darkGray)
                    
                    if autoStart && !detectedFaces.isEmpty {
                        Text("Starting in 2 seconds...")
                            .font(.caption)
                            .foregroundColor(.primaryRed)
                            .onAppear {
                                checkAutoStart()
                            }
                    }
                }
            }
            .padding()
            
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
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.lightGray)
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
                        .background(Color.primaryRed)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            if autoStart {
                // 얼굴 인식 완료 후 2초 대기하고 자동으로 룰렛 시작
                startAutoStartTimer()
            }
        }
        .onDisappear {
            autoStartTimer?.invalidate()
        }
    }
    
    private func startAutoStartTimer() {
        autoStartTimer?.invalidate()
        
        // 얼굴이 감지되고 처리가 완료되면 자동 시작
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
        // ⭐️ 새로운 좌표 변환 시스템 사용
        let displayBox = face.displayBoundingBox(for: imageSize)
        
        Rectangle()
            .stroke(Color.primaryRed.opacity(0.9), lineWidth: 2.5)
            .background(Color.primaryRed.opacity(0.1))
            .frame(width: displayBox.width, height: displayBox.height)
            .position(
                x: displayBox.midX,
                y: displayBox.midY
            )
            .overlay(
                // 얼굴 번호 배지 (더 선명하고 좋은 배치)
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(7)
                    .background(
                        Circle()
                            .fill(Color.primaryRed)
                            .shadow(color: Color.black.opacity(0.3), radius: 3)
                    )
                    .position(
                        x: displayBox.minX + 22,
                        y: displayBox.minY + 22
                    )
            )
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
