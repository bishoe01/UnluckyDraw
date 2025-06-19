//
//  ImageSourceManager.swift (formerly CameraManager.swift)
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import Foundation
import AVFoundation
import UIKit
import Photos

class ImageSourceManager: NSObject, ObservableObject {
    @Published var isCameraPermissionGranted = false
    @Published var isPhotoLibraryPermissionGranted = false
    @Published var selectedImage: UIImage?
    @Published var showImagePicker = false
    @Published var imageSourceType: UIImagePickerController.SourceType = .camera
    
    override init() {
        super.init()
        checkCameraPermission()
        checkPhotoLibraryPermission()
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraPermissionGranted = true
        case .notDetermined:
            requestCameraPermission()
        case .denied, .restricted:
            isCameraPermissionGranted = false
        @unknown default:
            isCameraPermissionGranted = false
        }
    }
    
    func checkPhotoLibraryPermission() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            isPhotoLibraryPermissionGranted = true
        case .notDetermined:
            requestPhotoLibraryPermission()
        case .denied, .restricted:
            isPhotoLibraryPermissionGranted = false
        @unknown default:
            isPhotoLibraryPermissionGranted = false
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isCameraPermissionGranted = granted
            }
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.isPhotoLibraryPermissionGranted = (status == .authorized || status == .limited)
            }
        }
    }
    
    func presentImageSource(_ sourceType: UIImagePickerController.SourceType) {
        print("📷 Present image source requested: \(sourceType)")
        
        imageSourceType = sourceType
        
        switch sourceType {
        case .camera:
            if isCameraPermissionGranted {
                print("📷 Camera permission granted, showing camera")
                DispatchQueue.main.async {
                    self.showImagePicker = true
                }
            } else {
                print("⚠️ Camera permission not granted, requesting permission")
                checkCameraPermission()
            }
        case .photoLibrary:
            if isPhotoLibraryPermissionGranted {
                print("🖼️ Photo library permission granted, showing gallery")
                DispatchQueue.main.async {
                    self.showImagePicker = true
                }
            } else {
                print("⚠️ Photo library permission not granted, requesting permission")
                checkPhotoLibraryPermission()
            }
        default:
            print("⚠️ Unsupported source type: \(sourceType)")
        }
    }
    
    func handleSelectedImage(_ image: UIImage?) {
        print("📷 Handle selected image called")
        DispatchQueue.main.async {
            self.selectedImage = image
            self.showImagePicker = false
            print("✅ Image processing completed")
        }
    }
    
    // Legacy support
    var capturedImage: UIImage? {
        get { selectedImage }
        set { selectedImage = newValue }
    }
    
    var showCamera: Bool {
        get { showImagePicker && imageSourceType == .camera }
        set { 
            if newValue {
                imageSourceType = .camera
            }
            showImagePicker = newValue 
        }
    }
    
    var isPermissionGranted: Bool {
        switch imageSourceType {
        case .camera:
            return isCameraPermissionGranted
        case .photoLibrary:
            return isPhotoLibraryPermissionGranted
        default:
            return false
        }
    }
}

// MARK: - ImagePicker for Camera
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("📷 Setting up camera picker")
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        
        // 카메라 최적화 설정
        if sourceType == .camera {
            print("📷 Configuring camera settings")
            
            // 기본 카메라 설정
            picker.cameraDevice = .rear
            picker.cameraCaptureMode = .photo
            
            // 미러링 비활성화 및 변환 제거
            picker.cameraViewTransform = CGAffineTransform.identity
            
            // 최대 해상도 설정 (더 빠른 처리를 위해 적당한 해상도)
            if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                print("📷 Camera device found: \(backCamera.localizedName)")
            }
            
            // 사용자 인터페이스 최적화
            picker.showsCameraControls = true
            
            // 성능 최적화
            picker.videoQuality = .typeHigh // 적당한 품질로 속도 향상
        }
        
        print("✅ Camera picker configured successfully")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📷 Image selection completed from: \(picker.sourceType == .camera ? "Camera" : "Photo Library")")
            
            if let originalImage = info[.originalImage] as? UIImage {
                print("🖼️ Original image received:")
                print("  Size: \(originalImage.size)")
                print("  Orientation: \(originalImage.imageOrientation.rawValue)")
                print("  Source: \(picker.sourceType == .camera ? "Camera" : "Gallery")")
                
                // 이미지 방향 보정 없이 그대로 사용
                // Vision Framework가 자동으로 방향을 처리합니다
                
                // 즉시 UI 업데이트
                DispatchQueue.main.async {
                    self.parent.selectedImage = originalImage
                    print("✅ Image passed to app without modification")
                    
                    // 이미지 피커 즉시 닫기
                    self.parent.isPresented = false
                }
            } else {
                print("❌ Failed to get original image")
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
