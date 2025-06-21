//
//  ImageSaveManager.swift
//  UnluckyDraw
//
//  Created on 2025-06-21
//

import UIKit
import Photos
import SwiftUI

class ImageSaveManager: ObservableObject {
    static let shared = ImageSaveManager()
    
    private init() {}
    
    // MARK: - Main Save Function
    
    /// 원본 이미지에 당첨자 얼굴 프레임을 그려서 저장
    func saveImageWithWinnerFrame(
        originalImage: UIImage,
        winner: DetectedFace,
        completion: @escaping (Result<Void, ImageSaveError>) -> Void
    ) {
        // 1. 권한 확인
        checkPhotoLibraryPermission { [weak self] hasPermission in
            guard hasPermission else {
                DispatchQueue.main.async {
                    completion(.failure(.permissionDenied))
                }
                return
            }
            
            // 2. 이미지 편집
            DispatchQueue.global(qos: .userInitiated).async {
                guard let editedImage = self?.drawWinnerFrameOnImage(
                    originalImage: originalImage,
                    winner: winner
                ) else {
                    DispatchQueue.main.async {
                        completion(.failure(.imageProcessingFailed))
                    }
                    return
                }
                
                // 3. 사진 라이브러리에 저장
                self?.saveImageToPhotoLibrary(editedImage) { result in
                    DispatchQueue.main.async {
                        completion(result)
                    }
                }
            }
        }
    }
    
    // MARK: - Image Editing
    
    private func drawWinnerFrameOnImage(originalImage: UIImage, winner: DetectedFace) -> UIImage? {
        let imageSize = originalImage.size
        let scale = originalImage.scale
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 1. 원본 이미지 그리기
        originalImage.draw(in: CGRect(origin: .zero, size: imageSize))
        
        // 2. Face Detection 좌표계 변환
        // Face Detection은 (0,0)이 좌하단, UIKit은 (0,0)이 좌상단
        // 또한 Vision 프레임워크는 normalized coordinates (0-1)를 사용
        
        let visionRect = winner.boundingBox
        
        // Vision 좌표를 UIKit 좌표로 변환
        let faceRect = CGRect(
            x: visionRect.origin.x * imageSize.width,
            y: (1.0 - visionRect.origin.y - visionRect.height) * imageSize.height, // Y축 뒤집기
            width: visionRect.width * imageSize.width,
            height: visionRect.height * imageSize.height
        )
        
        // 3. 프레임을 조금 더 크게 (여유 공간 추가)
        let padding: CGFloat = min(faceRect.width, faceRect.height) * 0.1 // 얼굴 크기의 10%
        let expandedRect = CGRect(
            x: max(0, faceRect.origin.x - padding),
            y: max(0, faceRect.origin.y - padding),
            width: min(imageSize.width - max(0, faceRect.origin.x - padding), faceRect.width + padding * 2),
            height: min(imageSize.height - max(0, faceRect.origin.y - padding), faceRect.height + padding * 2)
        )
        
        // 4. 빨간 프레임 그리기
        context.setStrokeColor(UIColor.systemRed.cgColor)
        context.setLineWidth(max(6.0, min(imageSize.width, imageSize.height) * 0.01)) // 이미지 크기에 비례한 선 두께
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // 프레임 모서리만 그리기 (더 세련되게)
        let cornerLength: CGFloat = min(expandedRect.width, expandedRect.height) * 0.2
        drawCornerFrame(context: context, rect: expandedRect, cornerLength: cornerLength)
        
        // 5. "ELIMINATED" 텍스트 추가
        let text = "☠️ ELIMINATED"
        let fontSize = min(imageSize.width, imageSize.height) * 0.04 // 이미지 크기에 비례한 폰트 크기
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .black),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.systemRed,
            .strokeWidth: -3.0
        ]
        
        let textSize = text.size(withAttributes: textAttributes)
        
        // 텍스트 위치 조정 - 얼굴 아래쪽이나 위쪽 중 더 여유있는 곳에 배치
        let textY: CGFloat
        if expandedRect.maxY + textSize.height + 20 < imageSize.height {
            // 얼굴 아래에 충분한 공간이 있으면 아래에
            textY = expandedRect.maxY + 10
        } else {
            // 공간이 없으면 얼굴 위에
            textY = max(0, expandedRect.minY - textSize.height - 10)
        }
        
        let textRect = CGRect(
            x: expandedRect.midX - textSize.width / 2,
            y: textY,
            width: textSize.width,
            height: textSize.height
        )
        
        // 텍스트 배경 (반투명 빨간색)
        context.setFillColor(UIColor.systemRed.withAlphaComponent(0.8).cgColor)
        let backgroundRect = textRect.insetBy(dx: -10, dy: -5)
        let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 8)
        context.addPath(backgroundPath.cgPath)
        context.fillPath()
        
        // 텍스트 그리기
        text.draw(in: textRect, withAttributes: textAttributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func drawCornerFrame(context: CGContext, rect: CGRect, cornerLength: CGFloat) {
        let corners = [
            // 좌상단
            (CGPoint(x: rect.minX, y: rect.minY + cornerLength), CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX + cornerLength, y: rect.minY)),
            // 우상단
            (CGPoint(x: rect.maxX - cornerLength, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + cornerLength)),
            // 우하단
            (CGPoint(x: rect.maxX, y: rect.maxY - cornerLength), CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX - cornerLength, y: rect.maxY)),
            // 좌하단
            (CGPoint(x: rect.minX + cornerLength, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY - cornerLength))
        ]
        
        for corner in corners {
            context.move(to: corner.0)
            context.addLine(to: corner.1)
            context.addLine(to: corner.2)
            context.strokePath()
        }
    }
    
    // MARK: - Photo Library Operations
    
    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage, completion: @escaping (Result<Void, ImageSaveError>) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            if success {
                completion(.success(()))
            } else {
                completion(.failure(.saveFailed(error?.localizedDescription ?? "Unknown error")))
            }
        }
    }
}

// MARK: - Error Types

enum ImageSaveError: Error, LocalizedError {
    case permissionDenied
    case imageProcessingFailed
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photo library access permission is required to save images."
        case .imageProcessingFailed:
            return "Failed to process the image."
        case .saveFailed(let message):
            return "Failed to save image: \(message)"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .permissionDenied:
            return "사진 라이브러리 접근 권한이 필요합니다.\n설정 > UnluckyDraw에서 권한을 허용해주세요."
        case .imageProcessingFailed:
            return "이미지 처리 중 오류가 발생했습니다."
        case .saveFailed:
            return "사진 저장에 실패했습니다."
        }
    }
}
