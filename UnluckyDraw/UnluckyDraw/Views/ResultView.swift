//
//  ResultView.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import SwiftUI

struct ResultView: View {
    let image: UIImage
    let winner: DetectedFace
    let totalFaces: Int
    let onPlayAgain: () -> Void
    let onClose: () -> Void
    
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (임팩트 있고 재미있게!) - 헤더 하나로 통합
            VStack(spacing: 12) {
                Text("☠️")
                    .font(.system(size: 60))
                    .scaleEffect(showAnimation ? 1.2 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showAnimation)
                
                Text("CAUGHT!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.unluckyRed)
                    .scaleEffect(showAnimation ? 1.0 : 0.3)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showAnimation)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            // Winner Image with Immediate Zoom
            GeometryReader { _ in
                ZStack {
                    // Background Image (더 라이트하게)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                        .brightness(-0.2)
                        .saturation(0.4)
                        .blur(radius: 1)
                    
                    // Large Winner Face - Immediate Display
                    LargeWinnerDisplay(
                        winner: winner,
                        originalImage: image,
                        showAnimation: showAnimation
                    )
                    
                    // 경고 효과 제거! 깔끔하게
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
            
            // 정보 카드 대폭 제거 (필요하면 그냥 간단하게 유지)
            // 삭제됨
            
            Spacer(minLength: 10)
            
            // Action Buttons (좌우 배치 옵션)
            HStack(spacing: 12) {
                // 메인으로 돌아가기 버튼
                Button(action: {
                    HapticManager.selection()
                    onClose()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Home")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.darkGray)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                // 다시 뛡기 버튼
                Button(action: {
                    HapticManager.impact()
                    onPlayAgain()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Try Again")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.unluckyRed, .unluckyOrange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: .unluckyRed.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .opacity(showAnimation ? 1.0 : 0.0)
            .animation(.easeInOut.delay(0.6), value: showAnimation)
        }
        .background(Color.lightGray.ignoresSafeArea())
        .onAppear {
            showAnimation = true
            
            // 강한 햄틱 피드백 ("어! 걸렸네!" 느낌)
            HapticManager.notification(.warning)
        }
    }
    
    private func calculateImageSize(geometry: GeometryProxy) -> CGSize {
        let maxWidth = geometry.size.width
        let maxHeight = geometry.size.height
        
        let imageAspectRatio = image.size.width / image.size.height
        let containerAspectRatio = maxWidth / maxHeight
        
        if imageAspectRatio > containerAspectRatio {
            let width = maxWidth
            let height = width / imageAspectRatio
            return CGSize(width: width, height: height)
        } else {
            let height = maxHeight
            let width = height * imageAspectRatio
            return CGSize(width: width, height: height)
        }
    }
    
    // MARK: - Helper Functions

    private func getFacePosition() -> Int {
        // 얼굴의 중심 좌표를 기준으로 위치 계산
        let centerX = winner.boundingBox.midX
        let centerY = winner.boundingBox.midY
        
        // 좌상단부터 1, 2, 3... 순서로 위치 번호 부여
        if centerY < 0.33 { // 상단
            if centerX < 0.33 { return 1 }
            else if centerX < 0.66 { return 2 }
            else { return 3 }
        } else if centerY < 0.66 { // 중간
            if centerX < 0.33 { return 4 }
            else if centerX < 0.66 { return 5 }
            else { return 6 }
        } else { // 하단
            if centerX < 0.33 { return 7 }
            else if centerX < 0.66 { return 8 }
            else { return 9 }
        }
    }
    
    private func getUnluckyScore() -> Int {
        // 얼굴 인식 신뢰도와 위치를 기반으로 "불운 점수" 계산
        let confidenceScore = Int(winner.confidence * 50) // 0-50점
        let positionScore = getFacePosition() * 5 // 5-45점
        let randomBonus = Int.random(in: 1 ... 10) // 1-10점 랜덤 보너스
        
        return min(100, confidenceScore + positionScore + randomBonus)
    }
}

// MARK: - Large Winner Display (재미있고 임팩트 있게!)

struct LargeWinnerDisplay: View {
    let winner: DetectedFace
    let originalImage: UIImage
    let showAnimation: Bool
    
    @State private var scale: CGFloat = 0.8
    @State private var flashOpacity: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 대형 얼굴 이미지 (재미있고 임팩트 있게!)
                if let croppedFace = winner.croppedImage {
                    VStack(spacing: 16) {
                        // 대형 얼굴 이미지 (경고 효과와 함께)
                        Image(uiImage: croppedFace)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 280, height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.unluckyRed, .warningYellow, .unluckyOrange]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 6
                                    )
                                    .opacity(1.0) // 고정된 투명도
                            )
                            .shadow(color: .unluckyRed.opacity(0.6), radius: 15)
                            .scaleEffect(scale)
                            .overlay(
                                // 깜박임 효과
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.unluckyRed.opacity(flashOpacity))
                            )
                        
                        // 재미있는 텍스트 (더 자연스럽게)
                        Text("☠️ THE VICTIM")
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.unluckyRed, .unluckyOrange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .unluckyRed.opacity(0.4), radius: 6)
                            )
                            .scaleEffect(scale)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 20)
                } else {
                    // 미리 크롭된 이미지가 없으면 기본 표시 (재미있는 폴백)
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 280, height: 280)
                            .overlay(
                                VStack {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.unluckyRed)
                                    Text("🎢 Victim!")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.unluckyRed, .warningYellow]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 6
                                    )
                            )
                            .scaleEffect(scale)
                        
                        Text("☠️ THE VICTIM")
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.unluckyRed)
                                    .shadow(color: .unluckyRed.opacity(0.4), radius: 6)
                            )
                            .scaleEffect(scale)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 20)
                }
            }
        }
        .onAppear {
            // 재미있고 임팩트 있는 애니메이션!
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            
            // 깜박임 효과 (어! 걸렸다! 느낌)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                    flashOpacity = 0.3
                }
            }
        }
    }
}

#Preview {
    ResultView(
        image: UIImage(systemName: "person.fill") ?? UIImage(),
        winner: DetectedFace(boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.3, height: 0.4), confidence: 0.95),
        totalFaces: 5,
        onPlayAgain: {},
        onClose: {}
    )
}
