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
                if granted {
                    // 권한 승인 후 자동으로 카메라 표시
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.showImagePicker = true
                    }
                }
            }
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                let granted = (status == .authorized || status == .limited)
                self?.isPhotoLibraryPermissionGranted = granted
                if granted {
                    // 권한 승인 후 자동으로 갤러리 표시
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.showImagePicker = true
                    }
                }
            }
        }
    }
    
    func presentImageSource(_ sourceType: UIImagePickerController.SourceType) {
        
        // 먼저 이전 상태 정리
        showImagePicker = false
        
        imageSourceType = sourceType
        
        switch sourceType {
        case .camera:
            if isCameraPermissionGranted {
                // 약간의 지연을 통해 UI 상태 안정화
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showImagePicker = true
                }
            } else {
                requestCameraPermission()
            }
        case .photoLibrary:
            if isPhotoLibraryPermissionGranted {
                // 약간의 지연을 통해 UI 상태 안정화
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showImagePicker = true
                }
            } else {
                requestPhotoLibraryPermission()
            }
        default:
            break
        }
    }
    
    func handleSelectedImage(_ image: UIImage?) {
        DispatchQueue.main.async {
            self.selectedImage = image
            self.showImagePicker = false
        }
    }
    
    // 상태 초기화 함수 추가
    func resetState() {
        DispatchQueue.main.async {
            self.selectedImage = nil
            self.showImagePicker = false
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
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        
        // 갤러리에서 선택할 때는 편집 가능하게 설정
        if sourceType == .photoLibrary {
            picker.allowsEditing = true  // 갤러리에서는 크롭 허용
        } else {
            picker.allowsEditing = false  // 카메라에서는 원본 사진 사용
        }
        
        // 카메라 최적화 설정
        if sourceType == .camera {
            
            // 기본 카메라 설정
            picker.cameraDevice = .rear
            picker.cameraCaptureMode = .photo
            
            // 미러링 비활성화 및 변환 제거
            picker.cameraViewTransform = CGAffineTransform.identity
            
            // 최대 해상도 설정 (더 빠른 처리를 위해 적당한 해상도)
            
            // 사용자 인터페이스 최적화
            picker.showsCameraControls = true
            
            // 성능 최적화
            picker.videoQuality = .typeHigh // 적당한 품질로 속도 향상
        }
        

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
            
            var finalImage: UIImage?
            
            // 갤러리에서 선택한 경우 편집된 이미지 우선 사용
            if picker.sourceType == .photoLibrary, let editedImage = info[.editedImage] as? UIImage {
                finalImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                finalImage = originalImage
            }
            
            if let image = finalImage {
                // 이미지 방향 보정 없이 그대로 사용
                // Vision Framework가 자동으로 방향을 처리합니다
                
                // 즉시 UI 업데이트
                DispatchQueue.main.async {
                    self.parent.selectedImage = image
                    
                    // 이미지 피커 즉시 닫기
                    self.parent.isPresented = false
                }
            } else {
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
