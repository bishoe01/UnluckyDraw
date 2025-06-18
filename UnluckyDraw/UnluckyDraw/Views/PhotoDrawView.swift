//
//  PhotoDrawView.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import SwiftUI

struct PhotoDrawView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var faceDetectionController = FaceDetectionController()
    @StateObject private var rouletteController = RouletteController()
    
    @State private var currentStep: PhotoDrawStep = .instruction
    @State private var showingResult = false
    
    enum PhotoDrawStep {
        case instruction
        case camera
        case faceDetection
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
                    case .instruction:
                        InstructionView {
                            proceedToCamera()
                        }
                        
                    case .camera:
                        ZStack {
                            Color.black.ignoresSafeArea()
                            
                            if cameraManager.isPermissionGranted {
                                // 카메라 즉시 표시
                                ImagePicker(
                                    selectedImage: $cameraManager.capturedImage,
                                    isPresented: $cameraManager.showCamera,
                                    sourceType: .camera
                                )
                                .onAppear {
                                    print("📷 Camera view appeared, opening camera immediately")
                                    if !cameraManager.showCamera {
                                        cameraManager.showCamera = true
                                    }
                                }
                            } else {
                                VStack(spacing: 20) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                    
                                    Text("Camera Permission Required")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Button("Grant Permission") {
                                        cameraManager.checkCameraPermission()
                                    }
                                    .foregroundColor(.primaryRed)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        
                    case .faceDetection:
                        if let image = cameraManager.capturedImage {
                            FaceDetectionView(
                                image: image,
                                detectedFaces: faceDetectionController.detectedFaces,
                                isProcessing: faceDetectionController.isProcessing,
                                error: faceDetectionController.error,
                                autoStart: true
                            ) {
                                proceedToRoulette()
                            }
                            .onAppear {
                                print("🔍 Starting face detection immediately")
                                faceDetectionController.detectFaces(in: image)
                            }
                        } else {
                            // 이미지가 없으면 즉시 카메라로 복귀
                            VStack {
                                ProgressView("Loading image...")
                                    .padding()
                                Text("Please wait...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .onAppear {
                                print("⚠️ No image found, returning to camera")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    currentStep = .camera
                                }
                            }
                        }
                        
                    case .roulette:
                        if let image = cameraManager.capturedImage {
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
                        if let image = cameraManager.capturedImage,
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
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            print("📷 Image capture detected: \(newImage != nil ? "SUCCESS" : "FAILED")")
            if newImage != nil {
                print("🔄 Transitioning to face detection immediately")
                // 즉시 전환
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .faceDetection
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
        case .instruction:
            return "1/4"
        case .camera:
            return "2/4"
        case .faceDetection:
            return "3/4"
        case .roulette:
            return "4/4"
        case .result:
            return ""
        }
    }
    
    private func proceedToCamera() {
        print("📷 User requested camera")
        currentStep = .camera
    }
    
    private func proceedToRoulette() {
        guard !faceDetectionController.detectedFaces.isEmpty else {
            print("⚠️ Cannot proceed to roulette: no faces detected")
            return
        }
        print("🎰 Proceeding to roulette with \(faceDetectionController.detectedFaces.count) faces")
        currentStep = .roulette
    }
    
    private func proceedToResult() {
        print("🏆 Proceeding to result")
        currentStep = .result
    }
    
    private func resetAndStart() {
        print("🔄 Resetting app state")
        cameraManager.capturedImage = nil
        faceDetectionController.clearResults()
        rouletteController.reset()
        currentStep = .instruction
        print("✅ App state reset completed")
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

#Preview {
    PhotoDrawView()
}
