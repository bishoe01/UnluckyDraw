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
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (간결하게 정리)
            VStack(spacing: 8) {
                Text("🎯")
                    .font(.system(size: 50))
                    .scaleEffect(showAnimation ? 1.1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showAnimation)
                
                Text("UNLUCKY WINNER!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryRed)
                    .scaleEffect(showAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showAnimation)
                
                Text("Out of \(totalFaces) participants")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .opacity(showAnimation ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.4), value: showAnimation)
            }
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Winner Image with Immediate Zoom
            GeometryReader { geometry in
                ZStack {
                    // Background Image (heavily dimmed)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                        .brightness(-0.6)
                        .saturation(0.1)
                        .blur(radius: 2)
                    
                    // Large Winner Face - Immediate Display
                    LargeWinnerDisplay(
                        winner: winner,
                        originalImage: image,
                        showAnimation: showAnimation
                    )
                    
                    // Confetti Effect
                    if showConfetti {
                        ConfettiView()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
            
            // Winner Info Card (컴팩하게 조정)
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.primaryOrange)
                    
                    Text("The Chosen One")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.darkGray)
                    
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Detection:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(Int(winner.confidence * 100))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.winnerGreen)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Face Position:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("#\(getFacePosition())")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryRed)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Unlucky Score:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(getUnluckyScore())/100")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryRed)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
            .scaleEffect(showAnimation ? 1.0 : 0.8)
            .opacity(showAnimation ? 1.0 : 0.0)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: showAnimation)
            
            Spacer(minLength: 10)
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    HapticManager.impact()
                    onPlayAgain()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                        Text("Play Again")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.primaryRed)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    HapticManager.selection()
                    onClose()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.lightGray)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .opacity(showAnimation ? 1.0 : 0.0)
            .animation(.easeInOut.delay(0.8), value: showAnimation)
        }
        .background(Color.lightGray.ignoresSafeArea())
        .onAppear {
            showAnimation = true
            
            // Success haptic feedback
            HapticManager.notification(.success)
            
            // Show confetti after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showConfetti = true
            }
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
        let randomBonus = Int.random(in: 1...10) // 1-10점 랜덤 보너스
        
        return min(100, confidenceScore + positionScore + randomBonus)
    }
}

// MARK: - Large Winner Display (Immediate)
struct LargeWinnerDisplay: View {
    let winner: DetectedFace
    let originalImage: UIImage
    let showAnimation: Bool
    
    @State private var scale: CGFloat = 0.8
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 대형 얼굴 이미지 (미리 크롭된 이미지 사용!)
                if let croppedFace = winner.croppedImage {
                    VStack(spacing: 16) {
                        // 대형 얼굴 이미지 (사각형 사진 형태)
                        Image(uiImage: croppedFace)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 280, height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.winnerGreen, .primaryOrange]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 6
                                    )
                            )
                            .shadow(color: .winnerGreen.opacity(0.3), radius: 15)
                            .scaleEffect(scale)
                            .overlay(
                                // 크라운 오버레이 (사진 위에 작게)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.primaryOrange)
                                    .rotationEffect(.degrees(rotationAngle))
                                    .shadow(color: .black.opacity(0.4), radius: 3)
                                    .offset(y: -160) // 사진 이미지 위로 이동
                            )
                        
                        // 당첨자 텍스트 (사진 아래)
                        Text("📷 THE UNLUCKY ONE")
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.primaryRed, .primaryOrange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .primaryRed.opacity(0.4), radius: 8)
                            )
                            .scaleEffect(scale)
                    }
                    .frame(maxWidth: .infinity) // 전체 너비 사용
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 20) // 약간 위로 이동
                } else {
                    // 미리 크롭된 이미지가 없으면 기본 표시 (폴백)
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 280, height: 280)
                            .overlay(
                                VStack {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.gray)
                                    Text("🏆 Winner!")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.primaryRed, lineWidth: 6)
                            )
                            .scaleEffect(scale)
                        
                        // 당첨자 텍스트 (폴백)
                        Text("🏆 THE UNLUCKY ONE")
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.primaryRed)
                                    .shadow(color: .primaryRed.opacity(0.4), radius: 8)
                            )
                            .scaleEffect(scale)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 20)
                }
            }
        }
        .onAppear {
            // 부드럽고 안정적인 애니메이션 (투명도 제거)
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)) {
                scale = 1.0
            }
            
            // 크라운 회전 효과 (더 자연스럽게)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                    rotationAngle = 6
                }
            }
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20) { index in
                ConfettiPiece(index: index)
                    .offset(y: animate ? 800 : -50)
                    .animation(
                        .linear(duration: Double.random(in: 2...4))
                        .delay(Double.random(in: 0...1)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    @State private var rotation: Double = 0
    
    private let colors: [Color] = [.primaryRed, .primaryOrange, .winnerGreen, .highlightYellow]
    
    var body: some View {
        Rectangle()
            .fill(colors[index % colors.count])
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .position(
                x: CGFloat.random(in: 50...350),
                y: 0
            )
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
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
