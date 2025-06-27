//
//  FaceFilterManager.swift
//  UnluckyDraw
//
//  Created on 2025-06-27
//

import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class FaceFilterManager {
    static let shared = FaceFilterManager()
    
    private let context = CIContext()
    
    private init() {}
    
    // MARK: - Main Filter Application
    
    func applyFilter(
        _ filter: FilterEffect,
        to image: UIImage,
        faceRect: CGRect
    ) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // UIKit 좌표를 CoreImage 좌표로 변환
        let imageHeight = ciImage.extent.height
        let coreImageFaceRect = CGRect(
            x: faceRect.origin.x,
            y: imageHeight - faceRect.origin.y - faceRect.height, // Y축 뒤집기
            width: faceRect.width,
            height: faceRect.height
        )
        
        let filteredImage: CIImage?
        
        switch filter {
        case .death:
            filteredImage = applyDeathEffect(to: ciImage, faceRect: coreImageFaceRect)
        case .whirlpool:
            filteredImage = applyWhirlpoolEffect(to: ciImage, faceRect: coreImageFaceRect)
        case .angel:
            filteredImage = applyAngelEffect(to: ciImage, faceRect: coreImageFaceRect)
        }
        
        guard let result = filteredImage else { return nil }
        
        // CIImage to UIImage 변환
        guard let cgImage = context.createCGImage(result, from: result.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Filter Implementations
    
    private func applyDeathEffect(to image: CIImage, faceRect: CGRect) -> CIImage? {
        let faceImage = image.cropped(to: faceRect)
        
        // 1. 어둡고 음산한 색조 변경
        let colorFilter = CIFilter.colorControls()
        colorFilter.inputImage = faceImage
        colorFilter.saturation = 0.2 // 채도 대폭 낮춤
        colorFilter.brightness = -0.4 // 밝기 대폭 낮춤
        colorFilter.contrast = 1.8 // 대비 높임
        
        guard let darkFace = colorFilter.outputImage else { return nil }
        
        // 2. 빨간색 틴트 추가 (피의 느낌)
        let tintFilter = CIFilter.colorMatrix()
        tintFilter.inputImage = darkFace
        tintFilter.rVector = CIVector(x: 1.3, y: 0.1, z: 0.1, w: 0)
        tintFilter.gVector = CIVector(x: 0.1, y: 0.6, z: 0.1, w: 0)
        tintFilter.bVector = CIVector(x: 0.1, y: 0.1, z: 0.6, w: 0)
        
        guard let tintedFace = tintFilter.outputImage else { return nil }
        
        return tintedFace.composited(over: image)
    }
    
    private func applyWhirlpoolEffect(to image: CIImage, faceRect: CGRect) -> CIImage? {
        // 얼굴을 소용돌이 모양으로 왜곡
        let filter = CIFilter.twirlDistortion()
        filter.inputImage = image
        filter.center = CGPoint(x: faceRect.midX, y: faceRect.midY)
        filter.radius = Float(max(faceRect.width, faceRect.height) * 0.8) // 얼굴 크기에 맞게 반지름 조정
        filter.angle = Float.pi * 3 // 더 강한 회전 효과
        
        return filter.outputImage
    }
    
    private func applyAngelEffect(to image: CIImage, faceRect: CGRect) -> CIImage? {
        let faceImage = image.cropped(to: faceRect)
        
        // 1. 밝고 따뜻한 색조로 변경
        let colorFilter = CIFilter.colorControls()
        colorFilter.inputImage = faceImage
        colorFilter.saturation = 1.2 // 채도 높임
        colorFilter.brightness = 0.2 // 밝기 높임
        colorFilter.contrast = 0.9 // 대비 살짝 낮춤 (부드러운 느낌)
        
        guard let brightFace = colorFilter.outputImage else { return nil }
        
        // 2. 황금색 틴트 추가 (천사의 후광 느낌)
        let tintFilter = CIFilter.colorMatrix()
        tintFilter.inputImage = brightFace
        tintFilter.rVector = CIVector(x: 1.1, y: 0.1, z: 0.0, w: 0)
        tintFilter.gVector = CIVector(x: 0.1, y: 1.1, z: 0.1, w: 0)
        tintFilter.bVector = CIVector(x: 0.0, y: 0.1, z: 0.8, w: 0)
        
        guard let goldenFace = tintFilter.outputImage else { return nil }
        
        // 3. 얼굴 주변에 부드러운 글로우 효과 추가
        let glowFilter = CIFilter.gaussianBlur()
        glowFilter.inputImage = goldenFace
        glowFilter.radius = 8
        
        guard let glowImage = glowFilter.outputImage else { return nil }
        
        // 글로우와 원본 얼굴 합성
        let compositeFilter = CIFilter.additionCompositing()
        compositeFilter.inputImage = goldenFace
        compositeFilter.backgroundImage = glowImage
        
        guard let angelFace = compositeFilter.outputImage else { return goldenFace }
        
        return angelFace.composited(over: image)
    }
}

// MARK: - Helper Extensions

extension CGRect {
    /// Vision 좌표계(normalized, origin at bottom-left)를 CoreImage 좌표계로 변환
    func convertFromVisionToCore(imageHeight: CGFloat) -> CGRect {
        return CGRect(
            x: self.origin.x,
            y: imageHeight - self.origin.y - self.height, // Y축 뒤집기
            width: self.width,
            height: self.height
        )
    }
}