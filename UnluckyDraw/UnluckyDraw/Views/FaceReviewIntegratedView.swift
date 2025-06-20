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
    
    var body: some View {
        VStack(spacing: 20) {
            // 🎰 통합 뷰에서도 아케이드 스타일 사용!
            if !faceDetectionController.isProcessing || faceDetectionController.error != nil || !faceDetectionController.editableFaces.isEmpty {
                ArcadeFaceCounter(
                    faceCount: faceDetectionController.editableFaces.count,
                    isProcessing: faceDetectionController.isProcessing,
                    hasError: faceDetectionController.error != nil
                )
                .padding(.top, 10)
            }
            
            // Main Content - 이미지와 편집 가능한 얼굴 박스들
            GeometryReader { geometry in
                ZStack {
                    // Background Image - 중앙 정렬 추가
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // 중앙 정렬을 위한 프레임
                        .cornerRadius(12)
                        .onAppear {
                            updateImageSizeIfNeeded(geometry: geometry)
                        }
                        .onChange(of: geometry.size) { _, _ in
                            updateImageSizeIfNeeded(geometry: geometry)
                        }
                    
                    // Processing Overlay (얼굴 인식 중일 때) - 중앙 정렬 추가
                    if faceDetectionController.isProcessing {
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // 중앙 정렬을 위한 프레임
                            .cornerRadius(12)
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Detecting faces...")
                                .font(.headline)
                                .foregroundColor(.adaptiveLabel)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // 중앙 정렬을 위한 프레임
                    }
                    
                    // Editable Face Boxes (인식 완료 후)
                    if !faceDetectionController.isProcessing && imageSize != .zero {
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
            
            Spacer()
            
            // Bottom Actions
            IntegratedBottomActionsView(
                isProcessing: faceDetectionController.isProcessing,
                hasError: faceDetectionController.error != nil,
                faceCount: faceDetectionController.editableFaces.count,
                onStart: startRoulette,
                onAddFace: addNewFace,
                onRetry: retryDetection,
                onRetakePhoto: onRetakePhoto // 새로운 콜백 전달
            )
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
            
            // ⭐️ 디버깅 로그 추가
            print("📊 FaceReviewIntegratedView - Image size changed:")
            print("  Original image: \(image.size)")
            print("  Container: \(geometry.size)")
            print("  Calculated display: \(newImageSize)")
            print("  Image aspect: \(String(format: "%.3f", image.size.width / image.size.height))")
            print("  Container aspect: \(String(format: "%.3f", geometry.size.width / geometry.size.height))")
            
            // 얼굴 인식이 완료되었고 editableFaces가 비어있다면 변환
            if !faceDetectionController.isProcessing &&
                !faceDetectionController.detectedFaces.isEmpty &&
                faceDetectionController.editableFaces.isEmpty
            {
                print("🔄 Converting detected faces to editable faces...")
                faceDetectionController.convertToEditableFaces(imageSize: newImageSize)
            }
        }
    }
    
    private func setupIntegratedMode() {
        print("🔍 Setting up integrated face detection and review mode")
        
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
            print("⚠️ Cannot start roulette: no faces available")
            return
        }
        
        HapticManager.impact(.heavy)
        print("🎰 Starting roulette with \(faceDetectionController.editableFaces.count) faces")
        onNext()
    }
    
    private func retryDetection() {
        HapticManager.impact(.medium)
        print("🔄 Retrying face detection")
        
        // 🎯 부드러운 전환을 위해 애니메이션과 함께 처리
        // 완전히 상태 초기화
        faceDetectionController.clearResults()
        
        // 약간의 지연 후 다시 얼굴 인식 시작 (안정적인 UI 전환을 위해)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.faceDetectionController.detectFaces(in: self.image)
        }
    }
}



// MARK: - Integrated Bottom Actions View

struct IntegratedBottomActionsView: View {
    let isProcessing: Bool
    let hasError: Bool
    let faceCount: Int
    let onStart: () -> Void
    let onAddFace: () -> Void
    let onRetry: () -> Void
    let onRetakePhoto: () -> Void // 새로운 콜백 추가
    
    var body: some View {
        if hasError {
            // Error State - 중앙 배치로 개선
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(.primaryOrange)
                    
                    VStack(spacing: 12) {
                        Text("🔍 No faces detected")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.adaptiveLabel)
                        
                        Text("Try taking the photo again")
                            .font(.body)
                            .foregroundColor(.adaptiveSecondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    VStack(spacing: 12) {
                        // Retake Photo 버튼
                        Button(action: onRetakePhoto) {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Retake Photo")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 40)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.primaryRed, .primaryOrange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .primaryRed.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                
                Spacer(minLength: 50) // 하단 여백
            }
        } else {
            // Normal State - 기존 레이아웃 유지
            VStack(spacing: 8) {
                if isProcessing {
                    // Processing State - 간단하게
                    VStack(spacing: 8) {
                        // 프로세싱 중에는 버튼 숨김
                    }
                } else {
                    // Success State - 텍스트 제거하고 버튼만
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
