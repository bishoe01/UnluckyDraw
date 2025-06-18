//
//  RouletteController.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import Foundation
import SwiftUI
import AVFoundation

class RouletteController: ObservableObject {
    @Published var currentHighlightedIndex: Int = 0
    @Published var isSpinning = false
    @Published var spinningSpeed: Double = 0.1
    @Published var winner: DetectedFace?
    
    private var spinTimer: Timer?
    private var faces: [DetectedFace] = []
    
    // 룰렛 애니메이션 설정
    private let initialSpeed: Double = 0.05  // 시작 속도 (빠름)
    private let finalSpeed: Double = 0.3     // 끝 속도 (느림)
    private let accelerationDuration: Double = 2.0  // 가속 시간
    private let totalSpinDuration: Double = 4.0     // 전체 스핀 시간
    
    func startRoulette(with faces: [DetectedFace]) {
        guard faces.count > 1 else {
            // 얼굴이 1개 이하면 바로 결과 표시
            if let singleFace = faces.first {
                self.winner = singleFace
                SoundManager.shared.playCaughtSound()
            }
            return
        }
        
        self.faces = faces
        self.isSpinning = true
        self.winner = nil
        self.currentHighlightedIndex = 0
        self.spinningSpeed = initialSpeed
        
        // 룰렛 시작 사운드
        SoundManager.shared.playStartSound()
        
        // 룰렛 타이머 시작
        startSpinAnimation()
        
        // 일정 시간 후 종료
        DispatchQueue.main.asyncAfter(deadline: .now() + totalSpinDuration) { [weak self] in
            self?.stopRoulette()
        }
    }
    
    private func startSpinAnimation() {
        spinTimer = Timer.scheduledTimer(withTimeInterval: spinningSpeed, repeats: true) { [weak self] _ in
            self?.updateHighlight()
        }
    }
    
    private func updateHighlight() {
        guard !faces.isEmpty else { return }
        
        // 다음 얼굴로 이동
        currentHighlightedIndex = (currentHighlightedIndex + 1) % faces.count
        
        // 시간에 따른 속도 조절 (점진적으로 느려짐)
        let elapsedTime = totalSpinDuration - (spinTimer?.fireDate.timeIntervalSinceNow ?? 0)
        let progress = min(elapsedTime / accelerationDuration, 1.0)
        
        // ease-out 효과로 속도 조절
        let easeOutProgress = 1 - pow(1 - progress, 3)
        spinningSpeed = initialSpeed + (finalSpeed - initialSpeed) * easeOutProgress
        
        // 타이머 재시작 (새로운 속도로)
        spinTimer?.invalidate()
        if isSpinning {
            startSpinAnimation()
        }
        
        // 룰렛 틱 사운드
        SoundManager.shared.playSpinSound()
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func stopRoulette() {
        isSpinning = false
        spinTimer?.invalidate()
        spinTimer = nil
        
        // 최종 당첨자 결정 (미리 크롭된 얼굴 이미지 포함!)
        if !faces.isEmpty {
            let winnerIndex = currentHighlightedIndex
            var winnerFace = faces[winnerIndex]
            winnerFace.isWinner = true
            self.winner = winnerFace
            
            print("🏆 Winner selected: Face \(winnerIndex + 1) with croppedImage: \(winnerFace.croppedImage != nil)")
        }
        
        // "걸렸다!" 사운드 (재미있고 임팩트 있게!)
        SoundManager.shared.playCaughtSound()
        
        // 차분한 햅틱 피드백 (성공이 아닌 선택 느낌)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        print("🎯 Winner selected: Face at index \(currentHighlightedIndex)")
    }
    
    func reset() {
        isSpinning = false
        spinTimer?.invalidate()
        spinTimer = nil
        currentHighlightedIndex = 0
        winner = nil
        faces.removeAll()
        spinningSpeed = initialSpeed
    }
    
    deinit {
        spinTimer?.invalidate()
    }
}
