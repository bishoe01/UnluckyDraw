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
    let currentPhase: Int  // 단계 정보 추가
    let onComplete: () -> Void
    
    @State private var showCompletionMessage = false
    
    var body: some View {
        ZStack {
            // 🌌 룰렛 중에는 전체 화면 어둡게
            if isSpinning {
                Color.black
                    .opacity(0.85)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: isSpinning)
            }
            
            VStack(spacing: 20) {
                // Status Header - 단계별 다른 메시지
                VStack(spacing: 8) {
                    if isSpinning {
                        HStack(spacing: 8) {
                            // 단계별 아이콘
                            getPhaseIcon()
                            
                            Text(getPhaseMessage())
                                .font(.headline)
                                .foregroundColor(getPhaseColor())
                                .animation(.easeInOut(duration: 0.3), value: currentHighlightedIndex)
                        }
                        
                        Text(getPhaseSubMessage())
                            .font(.caption)
                            .foregroundColor(.gray)
                            .animation(.easeInOut(duration: 0.3), value: currentHighlightedIndex)
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
                        // Background Image - 스포트라이트 효과를 위해 흑백 처리
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(16)
                            .saturation(0)  // 흑백 처리
                            .brightness(-0.2)
                            .overlay(
                                // 테두리 효과 - 룰렛 중에만
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.highlightYellow, .primaryOrange, .highlightYellow],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isSpinning ? 4 : 0
                                    )
                                    .shadow(color: .highlightYellow.opacity(0.6), radius: isSpinning ? 12 : 0)
                                    .animation(.easeInOut(duration: 0.3), value: isSpinning)
                            )
                        
                        // 🎯 고정된 프레임들 - 테두리 색상만 변경
                        ForEach(Array(faces.enumerated()), id: \.element.id) { index, face in
                            FixedFrameOverlay(
                                face: face,
                                index: index,
                                isHighlighted: index == currentHighlightedIndex,
                                isSpinning: isSpinning,
                                imageSize: calculateImageSize(geometry: geometry)
                            )
                        }
                        
                        // 🎆 스포트라이트 효과 - 선택된 얼굴만 컬러로
                        if isSpinning {
                            ForEach(Array(faces.enumerated()), id: \.element.id) { index, face in
                                if index == currentHighlightedIndex {
                                    SpotlightOverlay(
                                        face: face,
                                        originalImage: image,
                                        imageSize: calculateImageSize(geometry: geometry)
                                    )
                                }
                            }
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
                
                // Instructions - 단계별 다른 메시지
                if isSpinning {
                    Text(getBottomMessage())
                        .font(.headline)
                        .foregroundColor(getPhaseColor())
                        .padding()
                        .scaleEffect(currentHighlightedIndex % 2 == 0 ? 1.0 : 1.05) // 미세한 움직임
                        .animation(.easeInOut(duration: 0.1), value: currentHighlightedIndex)
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
    }
    
    // MARK: - 단계별 분위기 연출 함수들
    
    @ViewBuilder
    private func getPhaseIcon() -> some View {
        switch currentPhase {
        case 1:
            Image(systemName: "bolt.fill")
                .font(.title2)
                .foregroundColor(.orange)
        case 2:
            Image(systemName: "timer")
                .font(.title2)
                .foregroundColor(.red)
        default:
            ProgressView()
                .scaleEffect(0.8)
        }
    }
    
    private func getPhaseMessage() -> String {
        switch currentPhase {
        case 1:
            return "Spinning fast!"
        case 2:
            return "Slowing down..."
        default:
            return "Spinning..."
        }
    }
    
    private func getPhaseSubMessage() -> String {
        switch currentPhase {
        case 1:
            return "Spotlight moving!"
        case 2:
            return "Who will it be?!"
        default:
            return "Finding a victim..."
        }
    }
    
    private func getBottomMessage() -> String {
        switch currentPhase {
        case 1:
            return "⚡ Spotlight spinning!"
        case 2:
            return "🎰 Almost there!"
        default:
            return "🎰 Who will it be?"
        }
    }
    
    private func getPhaseColor() -> Color {
        switch currentPhase {
        case 1:
            return .orange
        case 2:
            return .red
        default:
            return .primaryRed
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

// MARK: - 🎯 고정된 프레임 오버레이 (테두리 색상만 변경)
struct FixedFrameOverlay: View {
    let face: DetectedFace
    let index: Int
    let isHighlighted: Bool
    let isSpinning: Bool
    let imageSize: CGSize
    
    var body: some View {
        let displayBox = face.displayBoundingBox(for: imageSize)
        
        ZStack {
            // 고정된 얼굴 프레임 - 테두리 색상만 변경
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHighlighted ? Color.highlightYellow : Color.primaryRed.opacity(0.4),
                    lineWidth: isHighlighted ? 4 : 2
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear) // 배경은 투명
                )
                .frame(width: displayBox.width, height: displayBox.height)
                .position(x: displayBox.midX, y: displayBox.midY)
                .shadow(
                    color: isHighlighted ? Color.highlightYellow.opacity(0.6) : Color.clear,
                    radius: isHighlighted ? 8 : 0
                )
                .animation(.easeInOut(duration: 0.15), value: isHighlighted)
            
            // 숫자 배지 - 룰렛 중에는 숨기고, 완료 후에만 표시
            if !isSpinning {
                Text("\(index + 1)")
                    .font(.system(size: isHighlighted ? 18 : 14, weight: .black))
                    .foregroundColor(isHighlighted ? .black : .white)
                    .padding(isHighlighted ? 10 : 8)
                    .background(
                        Circle()
                            .fill(isHighlighted ? Color.highlightYellow : Color.primaryRed)
                            .shadow(
                                color: isHighlighted ? Color.highlightYellow.opacity(0.4) : Color.black.opacity(0.2),
                                radius: isHighlighted ? 6 : 2
                            )
                    )
                    .position(
                        x: displayBox.minX + (isHighlighted ? 28 : 22),
                        y: displayBox.minY + (isHighlighted ? 28 : 22)
                    )
                    .scaleEffect(isHighlighted ? 1.2 : 1.0)
                    .opacity(isHighlighted ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.15), value: isHighlighted)
            }
        }
    }
}

// MARK: - 🎆 스포트라이트 효과 컴포넌트
struct SpotlightOverlay: View {
    let face: DetectedFace
    let originalImage: UIImage
    let imageSize: CGSize
    
    var body: some View {
        let displayBox = face.displayBoundingBox(for: imageSize)
        
        // 선택된 얼굴 영역만 컬러로 표시
        Image(uiImage: originalImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: imageSize.width, height: imageSize.height)
            .mask(
                // 얼굴 영역만 드러나게 마스크 처리
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: displayBox.width + 4, height: displayBox.height + 4) // 살짝 크게
                    .position(x: displayBox.midX, y: displayBox.midY)
            )
            .position(x: imageSize.width / 2, y: imageSize.height / 2)
            .animation(.easeInOut(duration: 0.15), value: face.id)
    }
}

#Preview {
    RouletteView(
        image: UIImage(systemName: "person.fill") ?? UIImage(),
        faces: [],
        currentHighlightedIndex: 0,
        isSpinning: true,
        currentPhase: 2,  // 미리보기용
        onComplete: {}
    )
}
