//
//  FaceDetectionController.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import Foundation
import Vision
import UIKit
import CoreImage
import AVFoundation
import AudioToolbox

class FaceDetectionController: ObservableObject {
    @Published var detectedFaces: [DetectedFace] = []
    @Published var editableFaces: [EditableFace] = []  // 🆕 Editable face list
    @Published var isProcessing = false
    @Published var error: FaceDetectionError?
    @Published var currentImageSize: CGSize = .zero    // 🆕 Current image size
    
    private var faceDetectionRequest: VNDetectFaceRectanglesRequest?
    private var originalImage: UIImage?  // 🆕 Store original image for manual box cropping
    
    enum FaceDetectionError: LocalizedError {
        case noFacesDetected
        case processingFailed
        case invalidImage
        
        var errorDescription: String? {
            switch self {
            case .noFacesDetected:
                return "No faces detected in the image"
            case .processingFailed:
                return "Failed to process the image"
            case .invalidImage:
                return "Invalid image provided"
            }
        }
    }
    
    init() {
        setupFaceDetection()
    }
    
    private func setupFaceDetection() {
        faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.processFaceDetectionResults(request: request, error: error)
            }
        }
        
        // Set face detection to maximum performance
        faceDetectionRequest?.revision = VNDetectFaceRectanglesRequestRevision3
        
        // Use GPU acceleration and performance optimization
        if #available(iOS 14.0, *) {
            faceDetectionRequest?.usesCPUOnly = false // Utilize GPU acceleration
        }
        

    }
    
    func detectFaces(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            self.error = .invalidImage
            return
        }
        
        isProcessing = true
        error = nil
        detectedFaces.removeAll()
        

        
        // Keep image preprocessing as is, but preserve orientation information
        let processedImage = preprocessImageForDetection(cgImage)
        
        // Set Vision to automatically handle image orientation
        let imageOrientation = cgImageOrientationFromUIImage(image.imageOrientation)
        
        let imageRequestHandler = VNImageRequestHandler(
            cgImage: processedImage,
            orientation: imageOrientation, // Important: pass original orientation information
            options: [:]
        )
        

        
        // ⭐️ 원본 이미지를 저장 (나중에 얼굴 크롭용)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let request = self?.faceDetectionRequest else { return }
            
            do {
                try imageRequestHandler.perform([request])
                
                // ⭐️ Crop all faces after Vision processing completes
                DispatchQueue.main.async {
                    self?.originalImage = image  // 🆕 Store original image
                    self?.cropAllDetectedFaces(from: image)
                    
                    // 🆕 If image size is set, immediately convert to editableFaces
                    if self?.currentImageSize != .zero {
                        self?.convertToEditableFaces(imageSize: self?.currentImageSize ?? .zero)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.error = .processingFailed
                    self?.isProcessing = false
                }
            }
        }
    }
    
    // UIImage.Orientation을 CGImagePropertyOrientation으로 변환
    private func cgImageOrientationFromUIImage(_ uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
    
    private func preprocessImageForDetection(_ cgImage: CGImage) -> CGImage {
        let context = CIContext(options: [.useSoftwareRenderer: false]) // GPU 사용
        let ciImage = CIImage(cgImage: cgImage)
        
        // Multi-stage image enhancement pipeline
        
        // Stage 1: Basic color correction
        let colorCorrected = ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputContrast": 1.3,      // Increase contrast
                "inputBrightness": 0.15,   // Slightly increase brightness
                "inputSaturation": 0.8     // Slightly decrease saturation
            ])
        
        // Stage 2: Sharpening (sharpen face contours)
        let sharpened = colorCorrected
            .applyingFilter("CISharpenLuminance", parameters: [
                "inputSharpness": 0.7
            ])
        
        // Stage 3: Noise reduction
        let denoised = sharpened
            .applyingFilter("CINoiseReduction", parameters: [
                "inputNoiseLevel": 0.02,
                "inputSharpness": 0.9
            ])
        
        // Stage 4: Gamma correction (clarify face areas)
        let gammaAdjusted = denoised
            .applyingFilter("CIGammaAdjust", parameters: [
                "inputPower": 0.85
            ])
        
        // Stage 5: Color temperature normalization (natural skin tone)
        let temperatureAdjusted = gammaAdjusted
            .applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: 6500, y: 0)
            ])
        
        // Generate final image
        if let outputCGImage = context.createCGImage(temperatureAdjusted, from: temperatureAdjusted.extent) {
            print("✨ Image preprocessing completed with \(outputCGImage.width)x\(outputCGImage.height) resolution")
            return outputCGImage
        }
        
        print("⚠️ Image preprocessing failed, using original")
        return cgImage
    }
    
    private func processFaceDetectionResults(request: VNRequest, error: Error?) {
        defer { isProcessing = false }
        
        if let error = error {
            self.error = .processingFailed
            return
        }
        
        guard let results = request.results as? [VNFaceObservation] else {
            self.error = .processingFailed
            return
        }
        
        if results.isEmpty {
            self.error = .noFacesDetected
            return
        }
        
        // 신뢰도 및 크기 기반 필터링 (더 엄격한 기준)
        let faces = results.compactMap { observation -> DetectedFace? in
            let boundingBox = observation.boundingBox
            let confidence = observation.confidence
            
            // 1. 신뢰도 검사 (더 엄격하게)
            guard confidence > 0.4 else {
                return nil
            }
            
            // 2. 얼굴 크기 검사 (너무 작은 얼굴 제외)
            let faceArea = boundingBox.width * boundingBox.height
            guard faceArea > 0.01 else { // 전체 이미지의 1% 이상
                return nil
            }
            
            // 3. 얼굴 비율 검사 (너무 길거나 넩은 얼굴 제외)
            let aspectRatio = boundingBox.width / boundingBox.height
            guard aspectRatio > 0.5 && aspectRatio < 2.0 else {
                return nil
            }
            
            // 4. 얼굴 위치 검사 (이미지 밖으로 너무 많이 나간 얼굴 제외)
            guard boundingBox.minX >= -0.1 && boundingBox.maxX <= 1.1 &&
                  boundingBox.minY >= -0.1 && boundingBox.maxY <= 1.1 else {
                return nil
            }
            
            // ⭐️ Vision 좌표계를 그대로 유지 (Y축 변환하지 않음)
            let face = DetectedFace(
                boundingBox: boundingBox, // Vision 원본 좌표 그대로 저장
                confidence: confidence
            )
            

            
            return face
        }
        
        // 필터링 후에도 얼굴이 없으면 에러
        if faces.isEmpty {
            self.error = .noFacesDetected
            return
        }
        
        // 🎰 원래 로직 유지하되, UI만 점진적으로 업데이트
        self.detectedFaces = faces
        
        // UI 애니메이션을 위한 별도 처리 (실제 데이터는 그대로)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 마지막에 완료 사운드만
            SoundManager.shared.playCompleteSound()
        }
        

    }
    
    // ⭐️ 완전히 새로운 얼굴 크롭 시스템
    private func cropAllDetectedFaces(from originalImage: UIImage) {
        
        // 이미지를 정규화된 방향으로 변환
        let normalizedImage = normalizeImageOrientation(originalImage)
        
        // 모든 얼굴을 크롭하여 저장
        for (index, face) in detectedFaces.enumerated() {
            if let croppedImage = advancedFaceCrop(from: normalizedImage, face: face) {
                detectedFaces[index].croppedImage = croppedImage
            }
        }
    }
    
    // 이미지 방향을 정규화 (항상 .up 상태로 만들기)
    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        // 이미지가 이미 정상 방향이면 그대로 반환
        if image.imageOrientation == .up {
            return image
        }
        
        // 정규화된 크기 계산
        let normalizedSize = CGSize(
            width: image.size.width,
            height: image.size.height
        )
        
        // 정규화된 이미지 생성
        UIGraphicsBeginImageContextWithOptions(normalizedSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: normalizedSize))
        
        if let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() {
            return normalizedImage
        }
        return image
    }
    
    // 고급 얼굴 크롭 함수
    private func advancedFaceCrop(from image: UIImage, face: DetectedFace) -> UIImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        // Vision 좌표계를 CGImage 좌표계로 변환
        // Vision: 좌하단 원점 (0,0), Y축 위쪽이 +
        // CGImage: 좌상단 원점 (0,0), Y축 아래쪽이 +
        let visionBox = face.boundingBox
        
        let cgBox = CGRect(
            x: visionBox.minX * imageWidth,
            y: (1.0 - visionBox.maxY) * imageHeight, // Y축 뒤집기
            width: visionBox.width * imageWidth,
            height: visionBox.height * imageHeight
        )
        

        
        // 얼굴 영역을 20% 확장 (안전하고 자연스러운 크롭)
        let expandRatio: CGFloat = 0.2
        let expandX = cgBox.width * expandRatio
        let expandY = cgBox.height * expandRatio
        
        let expandedBox = CGRect(
            x: max(0, cgBox.minX - expandX),
            y: max(0, cgBox.minY - expandY),
            width: min(imageWidth - max(0, cgBox.minX - expandX), cgBox.width + expandX * 2),
            height: min(imageHeight - max(0, cgBox.minY - expandY), cgBox.height + expandY * 2)
        )
        

        
        // 경계 검사
        guard expandedBox.width > 0 && expandedBox.height > 0 &&
              expandedBox.minX >= 0 && expandedBox.minY >= 0 &&
              expandedBox.maxX <= imageWidth && expandedBox.maxY <= imageHeight else {
            return nil
        }
        
        // 이미지 크롭
        guard let croppedCGImage = cgImage.cropping(to: expandedBox) else {
            return nil
        }
        
        // 크롭된 이미지가 너무 작으면 확대
        let minSize: CGFloat = 200
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: 1.0, orientation: .up)
        
        if max(croppedImage.size.width, croppedImage.size.height) < minSize {
            let scale = minSize / max(croppedImage.size.width, croppedImage.size.height)
            let newSize = CGSize(
                width: croppedImage.size.width * scale,
                height: croppedImage.size.height * scale
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            defer { UIGraphicsEndImageContext() }
            
            croppedImage.draw(in: CGRect(origin: .zero, size: newSize))
            
            if let scaledImage = UIGraphicsGetImageFromCurrentImageContext() {
                return scaledImage
            }
        }
        

        return croppedImage
    }
    
    func clearResults() {
        detectedFaces.removeAll()
        editableFaces.removeAll()
        error = nil
        isProcessing = false
        currentImageSize = .zero
    }
    
    // MARK: - 🆕 얼굴 편집 기능
    
    /// 얼굴 인식 결과를 편집 가능한 얼굴로 변환
    func convertToEditableFaces(imageSize: CGSize) {
        currentImageSize = imageSize
        editableFaces = detectedFaces.map { face in
            EditableFace(from: face, imageSize: imageSize)
        }
    }
    
    /// 새로운 얼굴 박스 추가 (향상된 버전)
    func addNewFace() {
        guard currentImageSize != .zero else {
            return
        }
        
        // 더 똑똑한 크기 계산
        let smartSize = calculateSmartBoxSize()
        let suggestedPosition = EditableFace.suggestPosition(
            for: smartSize,
            in: currentImageSize,
            avoiding: editableFaces
        )
        
        var newFace = EditableFace(
            boundingBox: CGRect(
                origin: suggestedPosition,
                size: smartSize
            ),
            confidence: 1.0,
            isUserAdded: true
        )
        
        // 🆕 수동 박스 추가 시 즉시 크롭 실행
        newFace.croppedImage = cropFaceFromEditableBox(newFace)
        
        editableFaces.append(newFace)
        
        // 시각적 피드백을 위해 잠시 하이라이트
        if let newIndex = editableFaces.firstIndex(where: { $0.id == newFace.id }) {
            editableFaces[newIndex].isHighlighted = true
            
            // 2초 후 하이라이트 해제
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if newIndex < self.editableFaces.count {
                    self.editableFaces[newIndex].isHighlighted = false
                }
            }
        }
    }
    
    /// 똑똑한 박스 크기 계산
    private func calculateSmartBoxSize() -> CGSize {
        if editableFaces.isEmpty {
            // 첫 번째 박스인 경우 이미지 크기에 비례한 기본 크기
            let defaultRatio: CGFloat = 0.15 // 이미지의 15%
            let size = min(currentImageSize.width, currentImageSize.height) * defaultRatio
            return CGSize(width: size, height: size * 1.2) // 약간 세로로 긴 형태
        }
        
        // 기존 박스들의 평균 크기 계산
        let averageSize = EditableFace.averageSize(from: editableFaces)
        
        // 크기 범위 제한 (너무 작거나 크지 않도록)
        let minSize: CGFloat = 60
        let maxSize = min(currentImageSize.width, currentImageSize.height) * 0.3
        
        let clampedWidth = max(minSize, min(maxSize, averageSize.width))
        let clampedHeight = max(minSize, min(maxSize, averageSize.height))
        
        return CGSize(width: clampedWidth, height: clampedHeight)
    }
    
    /// 얼굴 박스 삭제
    func removeFace(withId id: UUID) {
        guard editableFaces.count > 1 else {
            return
        }
        
        if let index = editableFaces.firstIndex(where: { $0.id == id }) {
            editableFaces.remove(at: index)
        }
    }
    
    /// 얼굴 박스 위치 업데이트 (향상된 버전)
    func updateFacePosition(id: UUID, dragOffset: CGSize) {
        if let index = editableFaces.firstIndex(where: { $0.id == id }) {
            editableFaces[index].dragOffset = dragOffset
            editableFaces[index].isDragging = true
        }
    }
    
    /// 드래그 완료 시 위치 적용 (향상된 버전)
    func finalizeFacePosition(id: UUID) {
        if let index = editableFaces.firstIndex(where: { $0.id == id }) {
            // 기존 로직 유지하면서 추가 검증
            editableFaces[index].applyDragOffset()
            editableFaces[index].constrainToImage(size: currentImageSize)
            
            // 🆕 사용자 추가 박스가 이동했으면 재크롭
            if editableFaces[index].isUserAdded {
                editableFaces[index].croppedImage = cropFaceFromEditableBox(editableFaces[index])
            }
        }
    }
    
    /// 박스가 이미지 경계 내에 있는지 확인
    private func isWithinBounds(_ box: CGRect) -> Bool {
        let imageBounds = CGRect(origin: .zero, size: currentImageSize)
        return imageBounds.contains(box)
    }
    
    /// 편집된 얼굴들을 DetectedFace 형태로 변환 (룰렛용)
    func getEditedFacesAsDetected() -> [DetectedFace] {
        return editableFaces.map { editableFace in
            // 픽셀 좌표를 Vision 좌표로 역변환
            let visionBox = CGRect(
                x: editableFace.boundingBox.minX / currentImageSize.width,
                y: 1.0 - (editableFace.boundingBox.maxY / currentImageSize.height),
                width: editableFace.boundingBox.width / currentImageSize.width,
                height: editableFace.boundingBox.height / currentImageSize.height
            )
            
            var detectedFace = DetectedFace(
                boundingBox: visionBox,
                confidence: editableFace.confidence
            )
            
            // 🆕 크롭 이미지가 없으면 즉석에서 생성 (안전장치)
            if let croppedImage = editableFace.croppedImage {
                detectedFace.croppedImage = croppedImage
            } else if editableFace.isUserAdded {
                detectedFace.croppedImage = cropFaceFromEditableBox(editableFace)
            }
            
            return detectedFace
        }
    }
    
    // MARK: - 🆕 수동 박스 크롭 시스템
    
    /// EditableFace 박스 영역을 원본 이미지에서 크롭
    private func cropFaceFromEditableBox(_ editableFace: EditableFace) -> UIImage? {
        guard let originalImage = originalImage else {
            return nil
        }
        
        guard let cgImage = originalImage.cgImage else {
            return nil
        }
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let boxInPixels = editableFace.boundingBox
        
        // 디스플레이 좌표를 실제 이미지 좌표로 변환
        let scaleX = imageWidth / currentImageSize.width
        let scaleY = imageHeight / currentImageSize.height
        
        let cropBox = CGRect(
            x: boxInPixels.minX * scaleX,
            y: boxInPixels.minY * scaleY,
            width: boxInPixels.width * scaleX,
            height: boxInPixels.height * scaleY
        )
        

        
        // 경계 검사
        let safeCropBox = CGRect(
            x: max(0, cropBox.minX),
            y: max(0, cropBox.minY),
            width: min(imageWidth - max(0, cropBox.minX), cropBox.width),
            height: min(imageHeight - max(0, cropBox.minY), cropBox.height)
        )
        
        guard safeCropBox.width > 0 && safeCropBox.height > 0 else {
            return nil
        }
        
        // 이미지 크롭
        guard let croppedCGImage = cgImage.cropping(to: safeCropBox) else {
            return nil
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: 1.0, orientation: .up)
        
        return croppedImage
    }
}
