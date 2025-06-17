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

class FaceDetectionController: ObservableObject {
    @Published var detectedFaces: [DetectedFace] = []
    @Published var isProcessing = false
    @Published var error: FaceDetectionError?
    
    private var faceDetectionRequest: VNDetectFaceRectanglesRequest?
    
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
        
        // 최대 성능으로 얼굴 인식 설정
        faceDetectionRequest?.revision = VNDetectFaceRectanglesRequestRevision3
        
        // GPU 가속 사용 및 성능 최적화
        if #available(iOS 14.0, *) {
            faceDetectionRequest?.usesCPUOnly = false // GPU 가속 활용
        }
        
        print("🤖 Face Detection initialized with max performance settings")
    }
    
    func detectFaces(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            self.error = .invalidImage
            return
        }
        
        isProcessing = true
        error = nil
        detectedFaces.removeAll()
        
        print("🔍 Processing image for face detection:")
        print("  Original size: \(image.size)")
        print("  Original orientation: \(image.imageOrientation.rawValue)")
        
        // 이미지 전처리는 그대로 유지하지만, 방향 정보를 보존
        let processedImage = preprocessImageForDetection(cgImage)
        
        // Vision이 이미지 방향을 자동으로 처리하도록 설정
        let imageOrientation = cgImageOrientationFromUIImage(image.imageOrientation)
        
        let imageRequestHandler = VNImageRequestHandler(
            cgImage: processedImage,
            orientation: imageOrientation, // 중요: 원본 방향 정보 전달
            options: [:]
        )
        
        print("🔍 Vision processing with orientation: \(imageOrientation.rawValue)")
        
        // ⭐️ 원본 이미지를 저장 (나중에 얼굴 크롭용)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let request = self?.faceDetectionRequest else { return }
            
            do {
                try imageRequestHandler.perform([request])
                
                // ⭐️ Vision 처리 완료 후 모든 얼굴 크롭
                DispatchQueue.main.async {
                    self?.cropAllDetectedFaces(from: image)
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ Face detection failed: \(error)")
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
        
        // 다단계 이미지 향상 파이프라인
        
        // 1단계: 기본 색상 보정
        let colorCorrected = ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputContrast": 1.3,      // 대비 증가
                "inputBrightness": 0.15,   // 밝기 약간 증가
                "inputSaturation": 0.8     // 채도 약간 감소
            ])
        
        // 2단계: 샤프닝 (얼굴 윤곽 선명하게)
        let sharpened = colorCorrected
            .applyingFilter("CISharpenLuminance", parameters: [
                "inputSharpness": 0.7
            ])
        
        // 3단계: 노이즈 제거
        let denoised = sharpened
            .applyingFilter("CINoiseReduction", parameters: [
                "inputNoiseLevel": 0.02,
                "inputSharpness": 0.9
            ])
        
        // 4단계: 감마 보정 (얼굴 영역 명확하게)
        let gammaAdjusted = denoised
            .applyingFilter("CIGammaAdjust", parameters: [
                "inputPower": 0.85
            ])
        
        // 5단계: 색온 정규화 (자연스러운 피부톤 연출)
        let temperatureAdjusted = gammaAdjusted
            .applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: 6500, y: 0)
            ])
        
        // 최종 이미지 생성
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
            print("Face detection error: \(error.localizedDescription)")
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
                print("❌ Rejected face with low confidence: \(String(format: "%.2f", confidence))")
                return nil
            }
            
            // 2. 얼굴 크기 검사 (너무 작은 얼굴 제외)
            let faceArea = boundingBox.width * boundingBox.height
            guard faceArea > 0.01 else { // 전체 이미지의 1% 이상
                print("❌ Rejected face with small area: \(String(format: "%.4f", faceArea))")
                return nil
            }
            
            // 3. 얼굴 비율 검사 (너무 길거나 넩은 얼굴 제외)
            let aspectRatio = boundingBox.width / boundingBox.height
            guard aspectRatio > 0.5 && aspectRatio < 2.0 else {
                print("❌ Rejected face with invalid aspect ratio: \(String(format: "%.2f", aspectRatio))")
                return nil
            }
            
            // 4. 얼굴 위치 검사 (이미지 밖으로 너무 많이 나간 얼굴 제외)
            guard boundingBox.minX >= -0.1 && boundingBox.maxX <= 1.1 &&
                  boundingBox.minY >= -0.1 && boundingBox.maxY <= 1.1 else {
                print("❌ Rejected face outside image bounds")
                return nil
            }
            
            // ⭐️ Vision 좌표계를 그대로 유지 (Y축 변환하지 않음)
            let face = DetectedFace(
                boundingBox: boundingBox, // Vision 원본 좌표 그대로 저장
                confidence: confidence
            )
            
            print("✅ Accepted face: confidence=\(String(format: "%.2f", confidence)), area=\(String(format: "%.4f", faceArea)), ratio=\(String(format: "%.2f", aspectRatio))")
            
            return face
        }
        
        self.detectedFaces = faces
        
        // 디버깅 정보 출력
        print("🎯 Face Detection Results:")
        print("  • Total detected: \(results.count)")
        print("  • Filtered faces: \(faces.count)")
        
        if faces.isEmpty {
            print("⚠️ No valid faces found after filtering")
            if !results.isEmpty {
                print("  Original detections were filtered out due to quality criteria")
            }
        } else {
            for (index, face) in faces.enumerated() {
                print("  Face \(index + 1): confidence=\(String(format: "%.2f", face.confidence)), area=\(String(format: "%.4f", face.boundingBox.width * face.boundingBox.height))")
            }
        }
        
        print("✅ Face detection completed successfully")
    }
    
    // ⭐️ 완전히 새로운 얼굴 크롭 시스템
    private func cropAllDetectedFaces(from originalImage: UIImage) {
        print("✂️ Starting advanced face cropping for \(detectedFaces.count) faces")
        
        // 이미지를 정규화된 방향으로 변환
        let normalizedImage = normalizeImageOrientation(originalImage)
        
        // 모든 얼굴을 크롭하여 저장
        for (index, face) in detectedFaces.enumerated() {
            if let croppedImage = advancedFaceCrop(from: normalizedImage, face: face) {
                detectedFaces[index].croppedImage = croppedImage
                print("✅ Face \(index + 1) cropped successfully: \(croppedImage.size)")
            } else {
                print("❌ Failed to crop face \(index + 1)")
            }
        }
        
        print("🎉 Advanced face cropping completed! Ready for roulette!")
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
            print("📐 Image orientation normalized: \(image.imageOrientation.rawValue) → \(normalizedImage.imageOrientation.rawValue)")
            return normalizedImage
        }
        
        print("⚠️ Failed to normalize image orientation, using original")
        return image
    }
    
    // 고급 얼굴 크롭 함수
    private func advancedFaceCrop(from image: UIImage, face: DetectedFace) -> UIImage? {
        guard let cgImage = image.cgImage else {
            print("❌ Cannot get CGImage from UIImage")
            return nil
        }
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        print("🔍 Image dimensions: \(imageWidth) x \(imageHeight)")
        print("🔍 Vision bounding box: \(face.boundingBox)")
        
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
        
        print("🔍 Converted CGImage box: \(cgBox)")
        
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
        
        print("🔍 Expanded box: \(expandedBox)")
        
        // 경계 검사
        guard expandedBox.width > 0 && expandedBox.height > 0 &&
              expandedBox.minX >= 0 && expandedBox.minY >= 0 &&
              expandedBox.maxX <= imageWidth && expandedBox.maxY <= imageHeight else {
            print("❌ Invalid crop box dimensions or out of bounds")
            return nil
        }
        
        // 이미지 크롭
        guard let croppedCGImage = cgImage.cropping(to: expandedBox) else {
            print("❌ Failed to crop CGImage")
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
                print("🔍 Face image scaled up to: \(scaledImage.size)")
                return scaledImage
            }
        }
        
        print("🔍 Final cropped face size: \(croppedImage.size)")
        return croppedImage
    }
    
    func clearResults() {
        detectedFaces.removeAll()
        error = nil
        isProcessing = false
    }
}
