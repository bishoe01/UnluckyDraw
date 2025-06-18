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
    @State private var isQuickAddMode = false
    @State private var quickAddCount = 0
    
    private let maxQuickAdd = 5
    
    var body: some View {
        VStack(spacing: 20) {
            // Header - 얼굴 인식 상태 + 검수 기능
            IntegratedHeaderView(
                isProcessing: faceDetectionController.isProcessing,
                error: faceDetectionController.error,
                faceCount: faceDetectionController.editableFaces.count,
                isQuickAddMode: isQuickAddMode,
                quickAddCount: quickAddCount,
                maxQuickAdd: maxQuickAdd,
                onAddFace: addNewFace,
                onToggleQuickAdd: toggleQuickAddMode,
                onBack: onBack
            )
            
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
                            calculateImageSize(geometry: geometry)
                        }
                        .onChange(of: geometry.size) { _, _ in
                            calculateImageSize(geometry: geometry)
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
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // 중앙 정렬을 위한 프레임
                    }
                    
                    // Editable Face Boxes (인식 완료 후)
                    if !faceDetectionController.isProcessing && imageSize != .zero {
                        ForEach(Array(faceDetectionController.editableFaces.enumerated()), id: \.element.id) { index, face in
                            EditableFaceBox(
                                face: face,
                                imageSize: imageSize,
                                index: index,
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
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Add a new face box for someone who wasn't detected automatically.")
        }
    }
    
    // MARK: - Functions
    
    private func calculateImageSize(geometry: GeometryProxy) {
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
        
        if imageSize != newImageSize {
            imageSize = newImageSize
            
            // 얼굴 인식이 완료되었고 editableFaces가 비어있다면 변환
            if !faceDetectionController.isProcessing && 
               !faceDetectionController.detectedFaces.isEmpty && 
               faceDetectionController.editableFaces.isEmpty {
                faceDetectionController.convertToEditableFaces(imageSize: newImageSize)
            }
        }
    }
    
    private func setupIntegratedMode() {
        print("🔍 Setting up integrated face detection and review mode")
        
        // 이미지 크기가 설정되어 있고 얼굴 인식이 완료되었다면 변환
        if imageSize != .zero && !faceDetectionController.detectedFaces.isEmpty && faceDetectionController.editableFaces.isEmpty {
            faceDetectionController.convertToEditableFaces(imageSize: imageSize)
        }
    }
    
    private func addNewFace() {
        HapticManager.impact(.medium)
        
        if isQuickAddMode {
            faceDetectionController.addNewFace()
            quickAddCount += 1
            
            if quickAddCount >= maxQuickAdd {
                toggleQuickAddMode()
            }
        } else {
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
    
    private func retryDetection() {
        HapticManager.impact(.medium)
        print("🔄 Retrying face detection")
        
        // 완전히 상태 초기화
        faceDetectionController.clearResults()
        
        // 약간의 지연 후 다시 얼굴 인식 시작 (UI 피드백을 위해)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.faceDetectionController.detectFaces(in: self.image)
        }
    }
}

// MARK: - Integrated Header View

struct IntegratedHeaderView: View {
    let isProcessing: Bool
    let error: FaceDetectionController.FaceDetectionError?
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
                
                // Title
                Text("Face Detection & Review")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.darkGray)
                
                Spacer()
                
                // Quick Add Toggle (얼굴 인식 완료 후에만 표시)
                if !isProcessing && error == nil {
                    Button(action: onToggleQuickAdd) {
                        HStack(spacing: 6) {
                            Image(systemName: isQuickAddMode ? "bolt.fill" : "bolt")
                                .font(.caption)
                            Text(isQuickAddMode ? "Quick" : "Quick")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(isQuickAddMode ? .white : .primaryRed)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isQuickAddMode ? Color.primaryRed : Color.clear)
                                .stroke(Color.primaryRed, lineWidth: 1)
                        )
                    }
                }
            }
            
            // Status Section
            if isProcessing {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing faces in your photo...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else if let error = error {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorDescription(error))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Text("You can manually add people using the + button")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                // Success State
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.winnerGreen)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Found \(faceCount) \(faceCount == 1 ? "person" : "people")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.darkGray)
                        
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Add Button
                    Button(action: onAddFace) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.primaryRed)
                            .scaleEffect(isQuickAddMode ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isQuickAddMode)
                    }
                }
            }
            
            // Quick Add Progress
            if isQuickAddMode && !isProcessing && error == nil {
                HStack {
                    Text("Quick Add Progress:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(quickAddCount)/\(maxQuickAdd)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryRed)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.3), value: isQuickAddMode)
            }
        }
        .padding(.horizontal)
    }
    
    private func errorDescription(_ error: FaceDetectionController.FaceDetectionError) -> String {
        switch error {
        case .noFacesDetected:
            return "No faces detected automatically"
        case .processingFailed:
            return "Face detection failed"
        case .invalidImage:
            return "Invalid image"
        }
    }
    
    private var statusMessage: String {
        if faceCount == 0 {
            return "Tap + to add people manually"
        } else if isQuickAddMode {
            return "Tap + to quickly add more (\(maxQuickAdd - quickAddCount) left)"
        } else {
            return "Drag boxes to adjust • Tap + to add more • Tap × to remove"
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
        VStack(spacing: 16) {
            if isProcessing {
                // Processing State
                VStack(spacing: 8) {
                    Text("Please wait while we detect faces...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            } else if hasError {
                // Error State - 0명 감지 시 "Try Again"만 강조
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("🔍 No faces detected automatically")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.darkGray)
                            .multilineTextAlignment(.center)
                        
                        Text("Try taking the photo again with better lighting or clearer faces.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 강조된 Try Again 버튼 - 카메라로 돌아가기
                    Button(action: onRetakePhoto) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill") // 카메라 아이콘으로 변경
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Retake Photo") // 텍스트도 명확하게 변경
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
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
                    
                    // 수동 추가는 작은 텍스트 링크로만 제공
                    Button(action: onAddFace) {
                        Text("Or try adding people manually first")
                            .font(.caption)
                            .foregroundColor(.primaryRed)
                            .underline()
                    }
                    .padding(.top, 4)
                }
            } else {
                // Success State
                VStack(spacing: 12) {
                    if faceCount > 0 {
                        Text("Perfect! Ready to start the draw.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    } else {
                        // 0명인 경우에도 수동 추가 유도
                        Text("Add people manually to get started.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
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
