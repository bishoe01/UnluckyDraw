//
//  ArcadeFaceCounter.swift
//  UnluckyDraw
//
//  Created on 2025-06-19
//

import SwiftUI

struct ArcadeFaceCounter: View {
    let faceCount: Int
    let isProcessing: Bool
    let hasError: Bool
    
    @State private var animatedCount: Int = 0
    @State private var isGlowing: Bool = false
    @State private var bounceScale: CGFloat = 1.0
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 16) {
            if isProcessing {
                processingView
            } else if hasError {
                errorView
            } else {
                successView
            }
        }
        .onChange(of: faceCount) { oldValue, newValue in
            animateCountChange(from: oldValue, to: newValue)
        }
        .onAppear {
            if !isProcessing && !hasError {
                animateCountChange(from: 0, to: faceCount)
            }
        }
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 12) {
            // 스캔 애니메이션 아이콘
            ZStack {
                Circle()
                    .stroke(Color.retroTeal.opacity(0.3), lineWidth: 3)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color.retroTeal,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(particleOffset))
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: particleOffset
                    )
                
                Image(systemName: "person.crop.square.badge.magnifyingglass")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.retroTeal)
            }
            .onAppear {
                particleOffset = 360
            }
            
            VStack(spacing: 6) {
                Text("🔍 SCANNING FACES")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.retroTeal)
                    .tracking(1.5)
                
                Text("AI 얼굴 인식 진행중...")
                    .font(.subheadline)
                    .foregroundColor(.adaptiveSecondaryLabel)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.primaryOrange.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.primaryOrange, lineWidth: 3)
                    )
                
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primaryOrange)
            }
            
            VStack(spacing: 6) {
                Text("😅 NO FACES FOUND")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryOrange)
                    .tracking(1.0)
                
                Text("다시 촬영해주세요!")
                    .font(.subheadline)
                    .foregroundColor(.adaptiveSecondaryLabel)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Success View (메인 이벤트!)
    private var successView: some View {
        VStack(spacing: 20) {
            // 메인 카운터 디스플레이
            ZStack {
                // 외곽 글로우 효과
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                countColor.opacity(isGlowing ? 0.4 : 0.2),
                                countColor.opacity(0.1),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 280, height: 120)
                    .scaleEffect(isGlowing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isGlowing)
                
                // 메인 배경
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.adaptiveSecondaryBackground,
                                Color.adaptiveTertiaryBackground
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 260, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [countColor.opacity(0.6), countColor.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: countColor.opacity(0.3), radius: 12, x: 0, y: 6)
                
                // 카운터 내용
                HStack(spacing: 20) {
                    // 얼굴 아이콘 스택
                    VStack(spacing: 4) {
                        ZStack {
                            ForEach(0..<min(animatedCount, 4), id: \.self) { index in
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(countColor)
                                    .offset(
                                        x: CGFloat(index % 2 == 0 ? -8 : 8),
                                        y: CGFloat(index < 2 ? -8 : 8)
                                    )
                                    .scaleEffect(bounceScale)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.6)
                                        .delay(Double(index) * 0.1),
                                        value: bounceScale
                                    )
                            }
                            
                            if animatedCount > 4 {
                                Text("+")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(countColor)
                            }
                        }
                        .frame(width: 40, height: 40)
                        
                        if animatedCount > 0 {
                            Text("FACES")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveTertiaryLabel)
                                .tracking(1.0)
                        }
                    }
                    
                    // 구분선
                    if animatedCount > 0 {
                        Rectangle()
                            .fill(countColor.opacity(0.3))
                            .frame(width: 2, height: 40)
                    }
                    
                    // 카운트 숫자 (메인 이벤트!)
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("\(animatedCount)")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundColor(countColor)
                                .scaleEffect(bounceScale)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animatedCount)
                            
                            if animatedCount > 0 {
                                Text("명")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(countColor)
                                    .offset(y: 8)
                            }
                        }
                        
                        Text(countMessage)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.adaptiveSecondaryLabel)
                            .tracking(0.5)
                    }
                }
            }
            
            // 상태 메시지
            if animatedCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.winnerGreen)
                    
                    Text(successMessage)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.adaptiveLabel)
                }
                .scaleEffect(bounceScale)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: bounceScale)
            }
        }
        .onAppear {
            isGlowing = true
        }
    }
    
    // MARK: - Computed Properties
    
    private var countColor: Color {
        switch animatedCount {
        case 0:
            return .gray
        case 1:
            return .retroTeal
        case 2...4:
            return .winnerGreen
        case 5...8:
            return .primaryOrange
        default:
            return .primaryRed
        }
    }
    
    private var countMessage: String {
        switch animatedCount {
        case 0:
            return ""
        case 1:
            return "발견!"
        case 2...4:
            return "좋아요!"
        case 5...8:
            return "대박!"
        default:
            return "와우!"
        }
    }
    
    private var successMessage: String {
        switch animatedCount {
        case 1:
            return "1명 발견! 룰렛 준비 완료"
        case 2...4:
            return "\(animatedCount)명 발견! 완벽한 인원이에요"
        case 5...8:
            return "\(animatedCount)명 발견! 치열한 경쟁이 될 듯!"
        default:
            return "\(animatedCount)명 발견! 엄청난 인원이네요!"
        }
    }
    
    // MARK: - Animation Functions
    
    private func animateCountChange(from oldValue: Int, to newValue: Int) {
        guard newValue != oldValue else { return }
        
        // 🎯 0으로 리셋되는 경우 지연 없이 말끔하게 처리
        if newValue == 0 {
            animatedCount = 0
            bounceScale = 1.0
            return
        }
        
        // 바운스 효과
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            bounceScale = 1.2
        }
        
        // 숫자 카운팅 애니메이션
        let duration = min(Double(abs(newValue - oldValue)) * 0.1, 1.0)
        withAnimation(.easeOut(duration: duration)) {
            animatedCount = newValue
        }
        
        // 바운스 복원
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                bounceScale = 1.0
            }
        }
        
        // 새로운 얼굴 발견 시 햅틱 피드백
        if newValue > oldValue {
            HapticManager.notification(.success)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // 처리 중
        ArcadeFaceCounter(faceCount: 0, isProcessing: true, hasError: false)
        
        // 에러
        ArcadeFaceCounter(faceCount: 0, isProcessing: false, hasError: true)
        
        // 성공 - 다양한 인원
        ArcadeFaceCounter(faceCount: 3, isProcessing: false, hasError: false)
    }
    .padding()
    .background(Color.adaptiveBackground)
}
