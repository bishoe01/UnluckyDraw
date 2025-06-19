//
//  PhotoDrawView.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import SwiftUI
import PhotosUI

struct PhotoDrawView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageSourceManager = ImageSourceManager()
    @StateObject private var faceDetectionController = FaceDetectionController()
    @StateObject private var rouletteController = RouletteController()
    
    @State private var currentStep: PhotoDrawStep = .sourceSelection
    @State private var selectedSourceType: UIImagePickerController.SourceType = .camera
    @State private var showingResult = false
    
    enum PhotoDrawStep {
        case sourceSelection       // 🆕 이미지 소스 선택 (카메라 vs 갤러리)
        case instruction          // 카메라용 지시사항
        case imageCapture         // 카메라 또는 갤러리
        case faceReviewIntegrated // 얼굴인식+검수 통합
        case roulette
        case result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.lightGray
                    .ignoresSafeArea()
                
                VStack {
                    // Navigation Bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.darkGray)
                        }
                        
                        Spacer()
                        
                        Text("Photo Draw")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Progress indicator
                        Text(stepDescription)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    // Main Content
                    switch currentStep {
                    case .sourceSelection:
                        ImageSourceSelectionView(
                            onCameraSelected: {
                                selectedSourceType = .camera
                                proceedToInstruction()
                            },
                            onGallerySelected: {
                                selectedSourceType = .photoLibrary
                                proceedToImageCapture()
                            }
                        )
                        
                    case .instruction:
                        InstructionView {
                            proceedToImageCapture()
                        }
                        
                    case .imageCapture:
                        ZStack {
                            Color.black.ignoresSafeArea()
                            
                            if imageSourceManager.isPermissionGranted {
                                // 이미지 소스 즉시 표시
                                ImagePicker(
                                    selectedImage: $imageSourceManager.selectedImage,
                                    isPresented: $imageSourceManager.showImagePicker,
                                    sourceType: selectedSourceType
                                )
                                .onAppear {
                                    let sourceTypeName = selectedSourceType == .camera ? "Camera" : "Gallery"
                                    print("📷 \(sourceTypeName) view appeared, opening \(sourceTypeName) immediately")
                                    if !imageSourceManager.showImagePicker {
                                        imageSourceManager.presentImageSource(selectedSourceType)
                                    }
                                }
                            } else {
                                VStack(spacing: 20) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                    
                                    Text("\(selectedSourceType == .camera ? "Camera" : "Photo Library") Permission Required")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Button("Grant Permission") {
                                        if selectedSourceType == .camera {
                                            imageSourceManager.checkCameraPermission()
                                        } else {
                                            imageSourceManager.checkPhotoLibraryPermission()
                                        }
                                    }
                                    .foregroundColor(.primaryRed)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        
                    case .faceReviewIntegrated:  // 🆕 얼굴인식+검수 통합 페이지
                        if let image = imageSourceManager.selectedImage {
                            FaceReviewIntegratedView(
                                image: image,
                                faceDetectionController: faceDetectionController,
                                onNext: {
                                    proceedToRoulette()
                                },
                                onBack: {
                                    currentStep = .imageCapture
                                },
                                onRetakePhoto: {
                                    retakePhoto() // 새로운 콜백 추가
                                }
                            )
                            .onAppear {
                                print("🔍 Starting integrated face detection and review")
                                if faceDetectionController.detectedFaces.isEmpty {
                                    faceDetectionController.detectFaces(in: image)
                                }
                            }
                        }
                        
                    case .roulette:
                        if let image = imageSourceManager.selectedImage {
                            RouletteView(
                                image: image,
                                faces: faceDetectionController.detectedFaces,
                                currentHighlightedIndex: rouletteController.currentHighlightedIndex,
                                isSpinning: rouletteController.isSpinning,
                                currentPhase: rouletteController.currentPhase  // 단계 정보 전달
                            ) {
                                proceedToResult()
                            }
                            .onAppear {
                                // 간단하게 룰렛 시작 (얼굴은 이미 크롭됨!)
                                rouletteController.startRoulette(with: faceDetectionController.detectedFaces)
                            }
                        }
                        
                    case .result:
                        if let image = imageSourceManager.selectedImage,
                           let winner = rouletteController.winner
                        {
                            ResultView(
                                image: image,
                                winner: winner,
                                totalFaces: faceDetectionController.detectedFaces.count
                            ) {
                                resetAndStart()
                            } onClose: {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: imageSourceManager.selectedImage) { _, newImage in
            print("📷 Image capture detected: \(newImage != nil ? "SUCCESS" : "FAILED")")
            if newImage != nil {
                print("🔄 Transitioning to integrated face review immediately")
                // 사진 촬영 후 바로 통합 페이지로 이동
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .faceReviewIntegrated
                }
            }
        }
        .onChange(of: rouletteController.winner) { _, newWinner in
            if newWinner != nil {
                print("🏆 Winner found, transitioning to result")
                // 안정적인 전환을 위해 약간 지연
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentStep = .result
                    }
                }
            }
        }
    }
    
    private var stepDescription: String {
        switch currentStep {
        case .sourceSelection:
            return "1/5"
        case .instruction:
            return "2/5"
        case .imageCapture:
            return "3/5"
        case .faceReviewIntegrated:
            return "4/5"
        case .roulette:
            return "5/5"
        case .result:
            return ""
        }
    }
    
    private func proceedToInstruction() {
        print("📝 User selected camera - showing instructions")
        currentStep = .instruction
    }
    
    private func proceedToImageCapture() {
        let sourceTypeName = selectedSourceType == .camera ? "Camera" : "Gallery"
        print("📷 User proceeding to \(sourceTypeName)")
        currentStep = .imageCapture
    }
    
    private func proceedToRoulette() {
        // 🆕 통합 페이지에서 바로 룰렛으로
        let finalFaces = faceDetectionController.getEditedFacesAsDetected()
        guard !finalFaces.isEmpty else {
            print("⚠️ Cannot proceed to roulette: no faces available")
            return
        }
        print("🎰 Proceeding to roulette with \(finalFaces.count) edited faces")
        
        // 편집된 얼굴들로 detectedFaces 업데이트
        faceDetectionController.detectedFaces = finalFaces
        currentStep = .roulette
    }
    
    private func proceedToResult() {
        print("🏆 Proceeding to result")
        currentStep = .result
    }
    
    private func resetAndStart() {
        print("🔄 Resetting app state")
        imageSourceManager.selectedImage = nil
        faceDetectionController.clearResults()
        rouletteController.reset()
        currentStep = .sourceSelection
        print("✅ App state reset completed")
    }
    
    private func retakePhoto() {
        let sourceTypeName = selectedSourceType == .camera ? "camera" : "gallery"
        print("📷 Retaking photo - clearing current image and going back to \(sourceTypeName)")
        
        // 현재 이미지와 얼굴 인식 결과 초기화
        imageSourceManager.selectedImage = nil
        faceDetectionController.clearResults()
        
        // 이미지 캡처 단계로 돌아가기
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .imageCapture
        }
        
        // 이미지 피커 다시 열기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.imageSourceManager.presentImageSource(self.selectedSourceType)
        }
        
        print("✅ Successfully returned to \(sourceTypeName) for retake")
    }
}

// MARK: - Instruction View

struct InstructionView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.primaryRed)
            
            // Instructions
            VStack(spacing: 16) {
                Text("Take a Group Photo")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.darkGray)
                
                VStack(spacing: 12) {
                    InstructionRow(
                        icon: "person.3.fill",
                        text: "Include multiple people in the frame"
                    )
                    InstructionRow(
                        icon: "eye.fill",
                        text: "Make sure all faces are clearly visible"
                    )
                    InstructionRow(
                        icon: "light.max",
                        text: "Good lighting helps face detection"
                    )
                }
            }
            
            Spacer()
            
            // Start Button
            Button(action: onNext) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.headline)
                    Text("Take Photo")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(Color.primaryRed)
                .cornerRadius(12)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 30)
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.primaryOrange)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.darkGray)
            
            Spacer()
        }
    }
}

// MARK: - Image Source Selection View

struct ImageSourceSelectionView: View {
    let onCameraSelected: () -> Void
    let onGallerySelected: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.primaryRed)
            
            // Title
            VStack(spacing: 16) {
                Text("Choose Photo Source")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.darkGray)
                
                Text("How would you like to get your photo?")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Options
            VStack(spacing: 16) {
                // Camera Option
                Button(action: onCameraSelected) {
                    HStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.primaryRed)
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Take New Photo")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.darkGray)
                            
                            Text("Use camera to capture a group photo")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Gallery Option
                Button(action: onGallerySelected) {
                    HStack(spacing: 16) {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.primaryOrange)
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Choose from Gallery")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.darkGray)
                            
                            Text("Select an existing photo from your gallery")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Footer
            Text("Both options will use the same drawing process")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 30)
        }
        .padding(.horizontal, 30)
    }
}

#Preview {
    PhotoDrawView()
}
