//
//  RouletteView.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import SwiftUI

struct RouletteView: View {
    let image: UIImage
    let faces: [DetectedFace]
    let currentHighlightedIndex: Int
    let isSpinning: Bool
    let onComplete: () -> Void
    
    @State private var showCompletionMessage = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Header
            VStack(spacing: 8) {
                if isSpinning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Spinning...")
                            .font(.headline)
                            .foregroundColor(.primaryRed)
                    }
                    
                    Text("Finding the unlucky one...")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "target")
                        .font(.system(size: 32))
                        .foregroundColor(.winnerGreen)
                    Text("Draw Complete!")
                        .font(.headline)
                        .foregroundColor(.darkGray)
                }
            }
            .padding()
            
            // Image with Roulette Animation
            GeometryReader { geometry in
                ZStack {
                    // Background Image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        .brightness(isSpinning ? -0.1 : 0)
                    
                    // Face Overlays with Roulette Effect
                    ForEach(Array(faces.enumerated()), id: \.element.id) { index, face in
                        RouletteOverlay(
                            face: face,
                            index: index,
                            isHighlighted: index == currentHighlightedIndex,
                            isSpinning: isSpinning,
                            imageSize: calculateImageSize(geometry: geometry)
                        )
                    }
                    
                    // Spinning Effect Overlay
                    if isSpinning {
                        SpinningEffectView()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Face Counter
            if faces.count > 1 {
                HStack {
                    Text("Participants:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ForEach(0..<faces.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentHighlightedIndex ? Color.highlightYellow : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentHighlightedIndex ? 1.5 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: currentHighlightedIndex)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // Instructions
            if isSpinning {
                Text("🎰 The wheel is spinning...")
                    .font(.headline)
                    .foregroundColor(.primaryRed)
                    .padding()
            }
        }
        .onChange(of: isSpinning) { spinning in
            if !spinning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCompletionMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onComplete()
                    }
                }
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
}

struct RouletteOverlay: View {
    let face: DetectedFace
    let index: Int
    let isHighlighted: Bool
    let isSpinning: Bool
    let imageSize: CGSize
    
    var body: some View {
        // ⭐️ 새로운 좌표 변환 시스템 사용
        let displayBox = face.displayBoundingBox(for: imageSize)
        
        ZStack {
            // 메인 얼굴 사각형 (더 엇은 두께, 더 잘 보이는 색상)
            Rectangle()
                .stroke(
                    isHighlighted ? Color.highlightYellow : Color.primaryRed.opacity(0.8),
                    lineWidth: isHighlighted ? 3 : 2
                )
                .background(
                    (isHighlighted ? Color.highlightYellow : Color.primaryRed)
                        .opacity(isHighlighted ? 0.15 : 0.08)
                )
                .frame(width: displayBox.width, height: displayBox.height)
                .position(x: displayBox.midX, y: displayBox.midY)
                .scaleEffect(isHighlighted ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isHighlighted)
            
            // 하이라이트 효과
            if isHighlighted {
                // 펄싱 테두리
                Rectangle()
                    .stroke(Color.highlightYellow, lineWidth: 4)
                    .frame(width: displayBox.width, height: displayBox.height)
                    .position(x: displayBox.midX, y: displayBox.midY)
                    .opacity(0.8)
                    .scaleEffect(1.1)
                    .animation(
                        .easeInOut(duration: 0.4).repeatForever(autoreverses: true),
                        value: isSpinning
                    )
                
                // 숫자 배지 (더 큰 사이즈, 더 선명한 색상)
                Text("\(index + 1)")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.highlightYellow)
                            .shadow(color: Color.highlightYellow.opacity(0.5), radius: 6)
                    )
                    .position(
                        x: displayBox.minX + 25,
                        y: displayBox.minY + 25
                    )
                    .scaleEffect(1.3)
            } else {
                // 일반 숫자 배지 (기존보다 약간 크게)
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.primaryRed)
                            .shadow(color: Color.black.opacity(0.3), radius: 2)
                    )
                    .position(
                        x: displayBox.minX + 20,
                        y: displayBox.minY + 20
                    )
            }
        }
    }
}

struct SpinningEffectView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Spinning rays
            ForEach(0..<8) { index in
                Rectangle()
                    .fill(Color.highlightYellow.opacity(0.3))
                    .frame(width: 2, height: 50)
                    .offset(y: -25)
                    .rotationEffect(.degrees(Double(index) * 45 + rotationAngle))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

#Preview {
    RouletteView(
        image: UIImage(systemName: "person.fill") ?? UIImage(),
        faces: [],
        currentHighlightedIndex: 0,
        isSpinning: true,
        onComplete: {}
    )
}
