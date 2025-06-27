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
    
    let initialSourceType: UIImagePickerController.SourceType
    let selectedFilter: FilterEffect
    
    @State private var currentStep: PhotoDrawStep = .instruction // 기본값 변경
    @State private var showingResult = false
    
    enum PhotoDrawStep {
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
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                VStack {
                    // Navigation Bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.adaptiveLabel)
                        }
                        
                        Spacer()
                        
                        Text("Photo Draw")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.adaptiveLabel)
                        
                        Spacer()
                        
                        // Progress indicator
                        Text(stepDescription)
                            .font(.caption)
                            .foregroundColor(.adaptiveSecondaryLabel)
                    }
                    .padding()
                    
                    // Main Content
                    switch currentStep {
                    case .instruction:
                        // 더 이상 사용되지 않음 - 직접 imageCapture로 이동
                        Color.clear.onAppear {
                            currentStep = .imageCapture
                        }
                        
                    case .imageCapture:
                        ZStack {
                            Color.black.ignoresSafeArea()
                            
                            if imageSourceManager.isPermissionGranted {
                                // 이미지 소스 즉시 표시
                                ImagePicker(
                                    selectedImage: $imageSourceManager.selectedImage,
                                    isPresented: $imageSourceManager.showImagePicker,
                                    sourceType: initialSourceType // 파라미터 사용
                                )
                                .onAppear {
                                    
                                    // 초기화 후 진행
                                    imageSourceManager.resetState()
                                    
                                    // 약간의 지연 후 다시 시도
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        if !self.imageSourceManager.showImagePicker {
                                            self.imageSourceManager.presentImageSource(self.initialSourceType)
                                        }
                                    }
                                }
                            } else {
                                PermissionRequestView(
                                    sourceType: initialSourceType, // 파라미터 사용
                                    onGrantPermission: {
                                        if initialSourceType == .camera {
                                            imageSourceManager.checkCameraPermission()
                                        } else {
                                            imageSourceManager.checkPhotoLibraryPermission()
                                        }
                                    },
                                    onBack: {
                                        // 뒤로 가기 대신 닫기
                                        dismiss()
                                    }
                                )
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
                                currentPhase: rouletteController.currentPhase,  // 단계 정보 전달
                                tensionLevel: rouletteController.tensionLevel   // 긴장감 레벨 전달
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
                                totalFaces: faceDetectionController.detectedFaces.count,
                                selectedFilter: selectedFilter
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
        .onAppear {
            // 초기 설정: 카메라와 갤러리 모두 바로 imageCapture로 시작
            currentStep = .imageCapture
        }
        .onChange(of: imageSourceManager.selectedImage) { _, newImage in
            if let image = newImage {
                
                // 사진 선택 후 바로 통합 페이지로 이동
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .faceReviewIntegrated
                }
            }
        }
        .onChange(of: rouletteController.winner) { _, newWinner in
            if newWinner != nil {
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
        case .instruction:
            return ""  // 더 이상 사용되지 않음
        case .imageCapture:
            return "1/3"
        case .faceReviewIntegrated:
            return "2/3"
        case .roulette:
            return "3/3"
        case .result:
            return ""
        }
    }
    
    // proceedToImageCapture() 함수 제거 - 더 이상 필요없음
    
    private func proceedToRoulette() {
        // 🆕 통합 페이지에서 바로 룰렟으로
        let finalFaces = faceDetectionController.getEditedFacesAsDetected()
        guard !finalFaces.isEmpty else {
            return
        }
        
        // 편집된 얼굴들로 detectedFaces 업데이트
        faceDetectionController.detectedFaces = finalFaces
        currentStep = .roulette
    }
    
    private func proceedToResult() {
        currentStep = .result
    }
    
    private func resetAndStart() {
        imageSourceManager.resetState()
        faceDetectionController.clearResults()
        rouletteController.reset()
        
        // 카메라와 갤러리 모두 바로 imageCapture로 시작
        currentStep = .imageCapture
    }
    
    private func retakePhoto() {
        
        // 🎯 부드러운 전환을 위해 애니메이션과 함께 처리
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .imageCapture
        }
        
        // 약간의 지연 후 데이터 초기화 (UI 전환 후)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.imageSourceManager.resetState()
            self.faceDetectionController.clearResults()
        }
        

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
                    .foregroundColor(.adaptiveLabel)
                
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
                .foregroundColor(.adaptiveSecondaryLabel)
            
            Spacer()
        }
    }
}

// MARK: - Permission Request View

struct PermissionRequestView: View {
    let sourceType: UIImagePickerController.SourceType
    let onGrantPermission: () -> Void
    let onBack: () -> Void
    
    private var iconName: String {
        sourceType == .camera ? "camera.fill" : "photo.fill"
    }
    
    private var title: String {
        sourceType == .camera ? "Camera Permission" : "Photo Library Permission"
    }
    
    private var description: String {
        sourceType == .camera 
            ? "UnluckyDraw needs camera access to take photos for the drawing game."
            : "UnluckyDraw needs photo library access to select existing photos for the drawing game."
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 80))
                .foregroundColor(.primaryRed)
            
            // Content
            VStack(spacing: 16) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.adaptiveLabel)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.adaptiveSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 16) {
                Button(action: onGrantPermission) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                        Text("Grant Permission")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(Color.primaryRed)
                    .cornerRadius(12)
                }
                
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                        Text("Go Back")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.adaptiveSecondaryLabel)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 30)
    }
}

#Preview {
    PhotoDrawView(initialSourceType: .camera, selectedFilter: .death)
}
