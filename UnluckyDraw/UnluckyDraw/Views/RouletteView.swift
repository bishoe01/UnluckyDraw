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
    let currentPhase: Int
    let tensionLevel: Double
    let onComplete: () -> Void
    
    @State private var pulseAnimation = false
    @State private var backgroundGradientOffset: CGFloat = 0
    @State private var lightningFlash = false
    
    var body: some View {
        ZStack {
            // 🌌 Dramatic animated background
            dramaticBackground
            
            // ⚡ Lightning flash effect for tension
            if currentPhase == 3 && tensionLevel > 0.7 {
                lightningFlashOverlay
            }
            
            VStack(spacing: 24) {
                // 🎯 Enhanced status header
                enhancedStatusHeader
                
                // 🖼️ Main image with advanced effects
                mainImageSection
                
                // 📊 Participant indicator
                participantIndicator
                
                Spacer()
                
                // 💫 Bottom instructions with phase-based styling
                bottomInstructions
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isSpinning) { _, spinning in
            if !spinning {
                onComplete()
            }
        }
        .onChange(of: currentPhase) { _, phase in
            if phase == 3 {
                // Extra dramatic effects for final phase
                HapticManager.impact(.heavy)
            }
        }
    }
    
    // MARK: - UI Components
    
    private var dramaticBackground: some View {
        ZStack {
            // Primary dark gradient matching other views
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black, location: 0.0),
                    .init(color: getPhaseColor().opacity(0.15), location: 0.3),
                    .init(color: Color.black.opacity(0.95), location: 0.7),
                    .init(color: Color.black, location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated overlay that responds to tension
            LinearGradient(
                gradient: Gradient(colors: [
                    getPhaseColor().opacity(0.08 + tensionLevel * 0.1),
                    Color.clear,
                    getPhaseColor().opacity(0.05 + tensionLevel * 0.08),
                    Color.clear
                ]),
                startPoint: UnitPoint(x: backgroundGradientOffset - 0.5, y: 0),
                endPoint: UnitPoint(x: backgroundGradientOffset + 0.5, y: 1)
            )
            .opacity(isSpinning ? 0.6 : 0.2)
        }
        .ignoresSafeArea()
    }
    
    private var lightningFlashOverlay: some View {
        Rectangle()
            .fill(Color.white.opacity(lightningFlash ? 0.3 : 0.0))
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.1), value: lightningFlash)
    }
    
    private var enhancedStatusHeader: some View {
        VStack(spacing: 16) {
            if isSpinning {
                // Phase icon with enhanced effects
                ZStack {
                    // Glow background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [getPhaseColor().opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseAnimation ? 1.3 : 0.8)
                    
                    getPhaseIcon()
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: getPhaseColor(), radius: 8)
                }
                
                // Phase message with dramatic styling
                VStack(spacing: 8) {
                    Text(getPhaseMessage())
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, getPhaseColor()],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(currentPhase == 3 ? 1.0 + tensionLevel * 0.1 : 1.0)
                        .shadow(color: getPhaseColor().opacity(0.6), radius: 4)
                    
                    Text(getPhaseSubMessage())
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                        .opacity(currentPhase == 3 ? 0.7 + tensionLevel * 0.3 : 1.0)
                }
                
                // Tension meter for final phase
                if currentPhase == 3 {
                    tensionMeter
                }
                
            } else {
                // Completion state
                VStack(spacing: 12) {
                    Text("💀")
                        .font(.system(size: 50))
                        .shadow(color: .red, radius: 10)
                    
                    Text("TARGET ELIMINATED")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .red.opacity(0.6), radius: 8)
                }
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }
    
    private var tensionMeter: some View {
        VStack(spacing: 8) {
            Text("TENSION LEVEL")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            HStack(spacing: 4) {
                ForEach(0..<10, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < Int(tensionLevel * 10) ? 
                              LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 20, height: 4)
                        .scaleEffect(y: index < Int(tensionLevel * 10) ? 1.5 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: tensionLevel)
                }
            }
        }
    }
    
    private var mainImageSection: some View {
        GeometryReader { geometry in
            let imageSize = calculateImageSize(geometry: geometry)
            
            ZStack {
                // Background image with phase-responsive effects
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .saturation(isSpinning ? 0.2 : 1.0) // Desaturated during spinning
                    .brightness(isSpinning ? -0.3 : 0.0)
                    .overlay(
                        // Dynamic border that responds to phase and tension
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: currentPhase == 3 ? 
                                        [.red, .orange, .red] :
                                        [getPhaseColor(), getPhaseColor().opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSpinning ? 3 + tensionLevel * 4 : 1
                            )
                            .shadow(
                                color: getPhaseColor().opacity(0.6 + tensionLevel * 0.4),
                                radius: isSpinning ? 12 + tensionLevel * 12 : 4
                            )
                    )
                    .scaleEffect(currentPhase == 3 ? 1.0 + tensionLevel * 0.02 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isSpinning)
                    .animation(.easeInOut(duration: 0.2), value: tensionLevel)
                    .animation(.easeInOut(duration: 0.3), value: currentPhase)
                
                // Spotlight effect for highlighted face
                if isSpinning {
                    ForEach(Array(faces.enumerated()), id: \.element.id) { index, face in
                        if index == currentHighlightedIndex {
                            EnhancedSpotlightOverlay(
                                face: face,
                                originalImage: image,
                                imageSize: imageSize,
                                containerSize: geometry.size,
                                tensionLevel: tensionLevel,
                                currentPhase: currentPhase
                            )
                        }
                    }
                }
                
                // Face frames with enhanced styling
                ForEach(Array(faces.enumerated()), id: \.element.id) { index, face in
                    EnhancedFixedFrameOverlay(
                        face: face,
                        index: index,
                        isHighlighted: index == currentHighlightedIndex,
                        isSpinning: isSpinning,
                        imageSize: imageSize,
                        containerSize: geometry.size,
                        tensionLevel: tensionLevel,
                        currentPhase: currentPhase
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: 400)
    }
    
    private var participantIndicator: some View {
        Group {
            if faces.count > 1 {
                VStack(spacing: 8) {
                    Text("PARTICIPANTS")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<faces.count, id: \.self) { index in
                            Circle()
                                .fill(
                                    index == currentHighlightedIndex ?
                                    LinearGradient(colors: [getPhaseColor(), getPhaseColor().opacity(0.6)], startPoint: .top, endPoint: .bottom) :
                                    LinearGradient(colors: [.gray.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .scaleEffect(index == currentHighlightedIndex ? 1.5 : 1.0)
                                .shadow(
                                    color: index == currentHighlightedIndex ? getPhaseColor().opacity(0.8) : .clear,
                                    radius: index == currentHighlightedIndex ? 4 : 0
                                )
                                .animation(.easeInOut(duration: 0.2), value: currentHighlightedIndex)
                        }
                    }
                }
                .padding(.horizontal, 20)
            } else {
                EmptyView()
            }
        }
    }
    
    private var bottomInstructions: some View {
        Group {
            if isSpinning {
                VStack(spacing: 12) {
                    Text(getBottomMessage())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, getPhaseColor()],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(currentPhase == 3 ? 1.0 + tensionLevel * 0.05 : 1.0)
                        .shadow(color: getPhaseColor().opacity(0.4), radius: 4)
                        .multilineTextAlignment(.center)
                    
                    if currentPhase == 3 {
                        Text("💀 FINAL MOMENTS 💀")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red.opacity(0.8))
                            .tracking(1)
                            .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Animation Functions
    
    private func startAnimations() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        // Background gradient animation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            backgroundGradientOffset = 1.0
        }
        
        // Lightning flash for high tension
        if currentPhase == 3 && tensionLevel > 0.7 {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                if currentPhase == 3 && tensionLevel > 0.7 {
                    withAnimation(.easeInOut(duration: 0.05)) {
                        lightningFlash = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeInOut(duration: 0.05)) {
                            lightningFlash = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Phase-based styling functions
    
    @ViewBuilder
    private func getPhaseIcon() -> some View {
        switch currentPhase {
        case 1:
            Image(systemName: "bolt.fill")
                .scaleEffect(1.0 + tensionLevel * 0.2)
        case 2:
            Image(systemName: "timer")
                .scaleEffect(1.0 + tensionLevel * 0.25)
                .rotationEffect(.degrees(tensionLevel * 15))
        case 3:
            Image(systemName: "target")
                .scaleEffect(1.0 + tensionLevel * 0.3)
                .rotationEffect(.degrees(tensionLevel * 20))
        default:
            ProgressView()
                .scaleEffect(0.8)
                .tint(.white)
        }
    }
    
    private func getPhaseMessage() -> String {
        switch currentPhase {
        case 1: return "⚡ SCANNING TARGETS"
        case 2: return "🎯 LOCKING ONTO TARGET"
        case 3: return "💀 FATE DECIDES NOW"
        default: return "🕹️ INITIALIZING..."
        }
    }
    
    private func getPhaseSubMessage() -> String {
        switch currentPhase {
        case 1: return "High-speed detection active"
        case 2: return "Narrowing down possibilities..."
        case 3: return "The moment of truth approaches..."
        default: return "Loading targeting system..."
        }
    }
    
    private func getBottomMessage() -> String {
        switch currentPhase {
        case 1: return "⚡ RAPID SCAN IN PROGRESS"
        case 2: return "🎯 TARGET ACQUISITION PHASE"
        case 3: return "💥 ELIMINATION IMMINENT"
        default: return "🕹️ SYSTEM INITIALIZING"
        }
    }
    
    private func getPhaseColor() -> Color {
        switch currentPhase {
        case 1: return .cyan
        case 2: return .orange
        case 3: return .red
        default: return .purple
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

// MARK: - Enhanced Components

struct EnhancedFixedFrameOverlay: View {
    let face: DetectedFace
    let index: Int
    let isHighlighted: Bool
    let isSpinning: Bool
    let imageSize: CGSize
    let containerSize: CGSize
    let tensionLevel: Double
    let currentPhase: Int
    
    var body: some View {
        // 정확한 좌표 변환 (ImageSaveManager와 동일한 로직)
        let visionRect = face.boundingBox
        
        // Vision 좌표를 UIKit 좌표로 변환
        let faceRect = CGRect(
            x: visionRect.origin.x * imageSize.width,
            y: (1.0 - visionRect.origin.y - visionRect.height) * imageSize.height, // Y축 뒤집기
            width: visionRect.width * imageSize.width,
            height: visionRect.height * imageSize.height
        )
        
        // 미세한 오차를 보정하기 위해 프레임을 약간 확장 (1-2픽셀)
        let expandedSpotlightRect = CGRect(
            x: faceRect.origin.x - 1,
            y: faceRect.origin.y - 1,
            width: faceRect.width + 2,
            height: faceRect.height + 2
        )
        
        // 미세한 오차를 보정하기 위해 프레임을 약간 확장 (1-2픽셀)
        let expandedFaceRect = CGRect(
            x: faceRect.origin.x - 1,
            y: faceRect.origin.y - 1,
            width: faceRect.width + 2,
            height: faceRect.height + 2
        )
        
        // 컨테이너 중앙 정렬을 위한 정확한 offset 계산
        let offsetX = (containerSize.width - imageSize.width) / 2
        let offsetY = (containerSize.height - imageSize.height) / 2
        
        // 추가적인 미세 조정 (패딩 및 경계 보정)
        let adjustedOffsetX = offsetX
        let adjustedOffsetY = offsetY
        
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isHighlighted ?
                LinearGradient(
                    colors: currentPhase == 3 ? [.red, .orange, .red] : [.cyan, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [.gray.opacity(0.4), .gray.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isHighlighted ? (currentPhase == 3 ? 6 : 4) : 2  // 둘께 변화 최소화
            )
            .frame(width: expandedFaceRect.width, height: expandedFaceRect.height)
            .position(
                x: expandedFaceRect.midX + adjustedOffsetX,
                y: expandedFaceRect.midY + adjustedOffsetY
            )
            .shadow(
                color: isHighlighted ? 
                    (currentPhase == 3 ? Color.red.opacity(0.8 + tensionLevel * 0.2) : Color.cyan.opacity(0.6)) :
                    Color.clear,
                radius: isHighlighted ? (currentPhase == 3 ? 15 + tensionLevel * 10 : 10) : 0
            )
            // scaleEffect 제거 - 이것이 위치 오차의 원인!
            // .scaleEffect(isHighlighted ? (currentPhase == 3 ? 1.05 + tensionLevel * 0.05 : 1.02) : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHighlighted)
            .animation(.easeInOut(duration: 0.2), value: tensionLevel)
    }
}

struct EnhancedSpotlightOverlay: View {
    let face: DetectedFace
    let originalImage: UIImage
    let imageSize: CGSize
    let containerSize: CGSize
    let tensionLevel: Double
    let currentPhase: Int
    
    var body: some View {
        // 정확한 좌표 변환 (ImageSaveManager와 동일한 로직)
        let visionRect = face.boundingBox
        
        // Vision 좌표를 UIKit 좌표로 변환
        let faceRect = CGRect(
            x: visionRect.origin.x * imageSize.width,
            y: (1.0 - visionRect.origin.y - visionRect.height) * imageSize.height, // Y축 뒤집기
            width: visionRect.width * imageSize.width,
            height: visionRect.height * imageSize.height
        )
        
        // 미세한 오차를 보정하기 위해 프레임을 약간 확장 (1-2픽셀)
        let expandedSpotlightRect = CGRect(
            x: faceRect.origin.x - 1,
            y: faceRect.origin.y - 1,
            width: faceRect.width + 2,
            height: faceRect.height + 2
        )
        
        // 컨테이너 중앙 정렬을 위한 offset 계산
        let offsetX = (containerSize.width - imageSize.width) / 2
        let offsetY = (containerSize.height - imageSize.height) / 2
        
        Image(uiImage: originalImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: imageSize.width, height: imageSize.height)
            .position(x: containerSize.width / 2, y: containerSize.height / 2)
            .clipped()
            .mask(
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: expandedSpotlightRect.width, height: expandedSpotlightRect.height)
                    .position(
                        x: expandedSpotlightRect.midX + offsetX,
                        y: expandedSpotlightRect.midY + offsetY
                    )
            )
            .saturation(currentPhase == 3 ? 1.5 + tensionLevel * 0.5 : 1.2)
            .brightness(currentPhase == 3 ? 0.2 + tensionLevel * 0.1 : 0.1)
            .animation(.easeInOut(duration: 0.2), value: tensionLevel)
    }
}

#Preview {
    RouletteView(
        image: UIImage(systemName: "person.fill") ?? UIImage(),
        faces: [],
        currentHighlightedIndex: 0,
        isSpinning: true,
        currentPhase: 3,
        tensionLevel: 0.9,
        onComplete: {}
    )
}
