//
//  FaceReviewIntegratedView.swift
//  UnluckyDraw
//
//  Created on 2025-06-18
//

import SwiftUI

struct FaceReviewIntegratedView: View {
    let image: UIImage
    @ObservedObject var faceDetectionController: FaceDetectionController
    let onNext: () -> Void
    let onBack: () -> Void
    let onRetakePhoto: () -> Void // 새로운 콜백 추가
    
    @State private var imageSize: CGSize = .zero
    @State private var showingAddConfirmation = false
    @State private var scanningRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // 🎰 얼굴 감지 성공 시에만 카운터 표시
            if !faceDetectionController.isProcessing && faceDetectionController.error == nil && !faceDetectionController.editableFaces.isEmpty {
                ArcadeFaceCounter(
                    faceCount: faceDetectionController.editableFaces.count,
                    isProcessing: false,
                    hasError: false
                )
                .padding(.top, 10)
            }
            
            // Main Content - 이미지와 편집 가능한 얼굴 박스들
            if faceDetectionController.isProcessing {
                // 🔍 얼굴 인식 진행 중 상태
                processingStateView
            } else if faceDetectionController.error != nil {
                // ❌ 얼굴 감지 실패 상태 (통합된 에러 UI)
                noFacesDetectedView
            } else {
                // ✅ 정상 상태 - 이미지와 편집 박스들
                normalStateImageView
            }
            
            Spacer()
            
            // Bottom Actions - 에러 상태가 아닐 때만 표시
            if faceDetectionController.error == nil {
                IntegratedBottomActionsView(
                    isProcessing: faceDetectionController.isProcessing,
                    hasError: false, // 에러는 위에서 처리하므로 항상 false
                    faceCount: faceDetectionController.editableFaces.count,
                    onStart: startRoulette,
                    onAddFace: addNewFace,
                    onRetry: retryDetection,
                    onRetakePhoto: onRetakePhoto
                )
            }
        }
        .onAppear {
            setupIntegratedMode()
        }
        .alert("Add New Person", isPresented: $showingAddConfirmation) {
            Button("Add") {
                faceDetectionController.addNewFace()
                HapticManager.notification(.success)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Add a new face box for someone who wasn't detected automatically.")
        }
    }
    
    // MARK: - Functions
    
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
        
        if imageSize != newImageSize {
            imageSize = newImageSize
            
            // ⭐️ FaceDetectionController의 currentImageSize도 업데이트
            faceDetectionController.currentImageSize = newImageSize
            
            // 얼굴 인식이 완료되었고 editableFaces가 비어있다면 변환
            if !faceDetectionController.isProcessing &&
                !faceDetectionController.detectedFaces.isEmpty &&
                faceDetectionController.editableFaces.isEmpty
            {
                faceDetectionController.convertToEditableFaces(imageSize: newImageSize)
            }
        }
    }
    
    private func setupIntegratedMode() {
        // ⭐️ FaceDetectionController의 currentImageSize 업데이트
        if imageSize != .zero {
            faceDetectionController.currentImageSize = imageSize
        }
        
        // 이미지 크기가 설정되어 있고 얼굴 인식이 완료되었다면 변환
        if imageSize != .zero && !faceDetectionController.detectedFaces.isEmpty && faceDetectionController.editableFaces.isEmpty {
            faceDetectionController.convertToEditableFaces(imageSize: imageSize)
        }
    }
    
    private func addNewFace() {
        HapticManager.impact(.medium)
        showingAddConfirmation = true
    }
    
    private func deleteFace(_ face: EditableFace) {
        HapticManager.impact(.medium)
        faceDetectionController.removeFace(withId: face.id)
    }
    
    private func startRoulette() {
        guard !faceDetectionController.editableFaces.isEmpty else {
            return
        }
        
        HapticManager.impact(.heavy)
        onNext()
    }
    
    private func retryDetection() {
        HapticManager.impact(.medium)
        
        // 🎯 부드러운 전환을 위해 애니메이션과 함께 처리
        // 완전히 상태 초기화
        faceDetectionController.clearResults()
        
        // 약간의 지연 후 다시 얼굴 인식 시작 (안정적인 UI 전환을 위해)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.faceDetectionController.detectFaces(in: self.image)
        }
    }
}

// MARK: - State Views

extension FaceReviewIntegratedView {
    // 🔍 얼굴 인식 진행 중 상태
    private var processingStateView: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 이미지
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                    .onAppear {
                        updateImageSizeIfNeeded(geometry: geometry)
                    }
                    .onChange(of: geometry.size) { _, _ in
                        updateImageSizeIfNeeded(geometry: geometry)
                    }
                
                // 처리 중 오버레이
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                
                // 스캔 애니메이션
                VStack(spacing: 20) {
                    // 스캔 아이콘
                    ZStack {
                        Circle()
                            .stroke(Color.retroTeal.opacity(0.3), lineWidth: 3)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                Color.retroTeal,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(scanningRotation))
                            .animation(
                                .linear(duration: 1.0).repeatForever(autoreverses: false),
                                value: scanningRotation
                            )
                        
                        Image(systemName: "person.crop.square.badge.magnifyingglass")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.retroTeal)
                    }
                    .onAppear {
                        scanningRotation = 360
                    }
                    
                    VStack(spacing: 8) {
                        Text("🔍 AI Face Detection...")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Please wait a moment")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // ❌ 얼굴 감지 실패 상태 (통합된 에러 UI)
    var noFacesDetectedView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 에러 아이콘
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.primaryOrange.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.primaryOrange, lineWidth: 3)
                        )
                    
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.primaryOrange)
                }
                
                VStack(spacing: 12) {
                    Text("😅 No faces found")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.adaptiveLabel)
                        .multilineTextAlignment(.center)
                    
                    Text("Please take another photo \nwith clear faces")
                        .font(.body)
                        .foregroundColor(.adaptiveSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            
            Spacer()
            
            // 액션 버튼들
            VStack(spacing: 16) {
                // 다시 촬영 버튼 (메인)
                Button(action: onRetakePhoto) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Retake Photo")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 40)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.primaryRed, .primaryOrange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .primaryRed.opacity(0.4), radius: 12, x: 0, y: 6)
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
    }
    
    // ✅ 정상 상태 - 이미지와 편집 박스들
    var normalStateImageView: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 이미지
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                    .onAppear {
                        updateImageSizeIfNeeded(geometry: geometry)
                    }
                    .onChange(of: geometry.size) { _, _ in
                        updateImageSizeIfNeeded(geometry: geometry)
                    }
                
                // 편집 가능한 얼굴 박스들
                if imageSize != .zero {
                    let calculatedImageSize = calculateImageSize(geometry: geometry)
                    let offsetX = (geometry.size.width - calculatedImageSize.width) / 2
                    let offsetY = (geometry.size.height - calculatedImageSize.height) / 2
                    
                    ForEach(Array(faceDetectionController.editableFaces.enumerated()), id: \.element.id) { index, face in
                        EditableFaceBox(
                            face: face,
                            imageSize: calculatedImageSize,
                            index: index,
                            offsetX: offsetX,
                            offsetY: offsetY,
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
    }
}

struct IntegratedBottomActionsView: View {
    let isProcessing: Bool
    let hasError: Bool
    let faceCount: Int
    let onStart: () -> Void
    let onAddFace: () -> Void
    let onRetry: () -> Void
    let onRetakePhoto: () -> Void
    
    var body: some View {
        // 에러 상태는 상위에서 처리하므로 여기서는 정상 상태만 처리
        VStack(spacing: 8) {
            if isProcessing {
                // 프로세싱 중에는 버튼 숨김
                VStack(spacing: 8) {
                    // 비어있음
                }
            } else {
                // 성공 상태 - 버튼들만 표시
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Add More Button (always visible)
                        Button(action: onAddFace) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.headline)
                                Text(faceCount == 0 ? "Add People" : "Add More")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.primaryRed)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primaryRed, lineWidth: 2)
                            )
                        }
                        
                        // Start Button (only when faces available)
                        if faceCount > 0 {
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
                                        .fill(Color.primaryRed)
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
}

#Preview {
    FaceReviewIntegratedView(
        image: UIImage(systemName: "person.fill") ?? UIImage(),
        faceDetectionController: FaceDetectionController(),
        onNext: {},
        onBack: {},
        onRetakePhoto: {} // 새로운 콜백 추가
    )
}
