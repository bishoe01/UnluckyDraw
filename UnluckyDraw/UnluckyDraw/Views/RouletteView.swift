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
                    let imageSize = calculateImageSize(geometry: geometry)
                    
                    ZStack {
                        // Background Image - 스포트라이트 효과를 위해 흑백 처리
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // 중앙 정렬을 위한 프레임
                            .cornerRadius(16)
                            .saturation(0)  // 흑백 처리
                            .brightness(-0.2)
                            .overlay(
                                // 테두리 효과 - 룰렛 중에만 (레트로 게임 컬러)
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.retroTeal, .retroPurple, .retroMint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isSpinning ? 4 : 0
                                    )
                                    .shadow(color: .retroTeal.opacity(0.6), radius: isSpinning ? 12 : 0)
                                    .animation(.easeInOut(duration: 0.3), value: isSpinning)
                            )
                        
                        // 🎆 스포트라이트 효과 - 선택된 얼굴만 컬러로 (먼저 배치)
                        if isSpinning {
                            ForEach(Array(faces.enumerated()), id: \.element.id) { index, face in
                                if index == currentHighlightedIndex {
                                    SpotlightOverlay(
                                        face: face,
                                        originalImage: image,
                                        imageSize: imageSize,
                                        containerSize: geometry.size
                                    )
                                }
                            }
                        }
                        
                        // 🎯 고정된 프레임들 - 테두리 색상만 변경 (나중에 배치해서 위에 표시)
                        ForEach(Array(faces.enumerated()), id: \.element.id) { index, face in
                            FixedFrameOverlay(
                                face: face,
                                index: index,
                                isHighlighted: index == currentHighlightedIndex,
                                isSpinning: isSpinning,
                                imageSize: imageSize,
                                containerSize: geometry.size
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Face Counter (레트로 컬러)
                if faces.count > 1 {
                    HStack {
                        Text("Participants:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ForEach(0..<faces.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentHighlightedIndex ? Color.retroTeal : Color.gray.opacity(0.3))
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
            .onChange(of: isSpinning) { _, spinning in
                if !spinning {
                    // 룰렛이 끝나면 즉시 ResultView로 전환 (숫자 배지 표시 없음)
                    onComplete()
                }
            }
        }
    }
    
    // MARK: - 단계별 분위기 연출 함수들 (레트로 게임 스타일)
    
    @ViewBuilder
    private func getPhaseIcon() -> some View {
        switch currentPhase {
        case 1:
            Image(systemName: "bolt.fill")
                .font(.title2)
                .foregroundColor(.retroTeal)
        case 2:
            Image(systemName: "timer")
                .font(.title2)
                .foregroundColor(.retroPink)
        default:
            ProgressView()
                .scaleEffect(0.8)
                .tint(.retroPurple)
        }
    }
    
    private func getPhaseMessage() -> String {
        switch currentPhase {
        case 1:
            return "Scanning players!"
        case 2:
            return "Target locking..."
        default:
            return "Initializing..."
        }
    }
    
    private func getPhaseSubMessage() -> String {
        switch currentPhase {
        case 1:
            return "Retro scanner active!"
        case 2:
            return "System selecting..."
        default:
            return "Loading game data..."
        }
    }
    
    private func getBottomMessage() -> String {
        switch currentPhase {
        case 1:
            return "🕹️ Retro scanner active!"
        case 2:
            return "🎯 Target acquired!"
        default:
            return "🕹️ System loading..."
        }
    }
    
    private func getPhaseColor() -> Color {
        switch currentPhase {
        case 1:
            return .retroTeal
        case 2:
            return .retroPink
        default:
            return .retroPurple
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

// MARK: - 🎯 고정된 프레임 오버레이 (레트로 게임 컬러)
struct FixedFrameOverlay: View {
    let face: DetectedFace
    let index: Int
    let isHighlighted: Bool
    let isSpinning: Bool
    let imageSize: CGSize
    let containerSize: CGSize // 컨테이너 크기 추가
    
    var body: some View {
        let displayBox = face.displayBoundingBox(for: imageSize)
        
        // 이미지가 컨테이너 중앙에 위치하도록 offset 계산
        let offsetX = (containerSize.width - imageSize.width) / 2
        let offsetY = (containerSize.height - imageSize.height) / 2
        
        // 고정된 얼굴 프레임 - 레트로 게임 스타일 테두리
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isHighlighted ? 
                LinearGradient(
                    colors: [.retroTeal, .retroMint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) : 
                LinearGradient(
                    colors: [.retroPurple.opacity(0.4), .retroCharcoal.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isHighlighted ? 4 : 2
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear) // 배경은 투명
            )
            .frame(width: displayBox.width, height: displayBox.height)
            .position(
                x: displayBox.midX + offsetX,
                y: displayBox.midY + offsetY
            )
            .shadow(
                color: isHighlighted ? Color.retroTeal.opacity(0.8) : Color.clear,
                radius: isHighlighted ? 12 : 0
            )
            .animation(.easeInOut(duration: 0.15), value: isHighlighted)
    }
}

// MARK: - 🎆 스포트라이트 효과 컴포넌트 (얼굴 밀림 현상 완전 해결)
struct SpotlightOverlay: View {
    let face: DetectedFace
    let originalImage: UIImage
    let imageSize: CGSize
    let containerSize: CGSize // 컨테이너 크기 추가
    
    var body: some View {
        let displayBox = face.displayBoundingBox(for: imageSize)
        
        // 이미지가 컨테이너 중앙에 위치하도록 offset 계산
        let offsetX = (containerSize.width - imageSize.width) / 2
        let offsetY = (containerSize.height - imageSize.height) / 2
        
        // 🔧 완전히 새로운 접근: 클립핑 방식으로 위치 오차 제거
        Image(uiImage: originalImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: imageSize.width, height: imageSize.height)
            .position(
                x: containerSize.width / 2,
                y: containerSize.height / 2
            )
            .clipped()
            .mask(
                // 정확히 동일한 좌표와 크기로 마스크 - 둘근 모서리도 동일하게!
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: displayBox.width, height: displayBox.height)
                    .position(
                        x: displayBox.midX + offsetX,
                        y: displayBox.midY + offsetY
                    )
            )
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
