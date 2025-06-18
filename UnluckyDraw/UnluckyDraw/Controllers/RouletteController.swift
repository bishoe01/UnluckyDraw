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
    
    // 🎲 자연스러운 2단계 룰렛 시스템
    private let phase1Duration: Double = 1.5   // 1단계: 적당히 빠르게 시작
    private let phase2Duration: Double = 3.0   // 2단계: 점진적 감속  
    private let totalSpinDuration: Double = 4.5 // 전체 시간
    
    // 각 단계별 속도 - 자연스럽게
    private let phase1Speed: Double = 0.12     // 적당히 빠른 시작
    private let phase2StartSpeed: Double = 0.12 // 감속 시작 속도
    private let phase2EndSpeed: Double = 0.8   // 마지막에 적당히 느리게
    
    @Published var currentPhase: Int = 1
    @Published var spinStartTime: Date = Date()
    
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
        self.currentPhase = 1
        self.spinStartTime = Date()
        self.spinningSpeed = phase1Speed
        
        print("🎲 룰렛 시작! 2단계 시스템 (총 \(totalSpinDuration)초)")
        
        // 룰렛 시작 사운드
        SoundManager.shared.playStartSound()
        
        // 1단계: 적당히 빠른 시작
        startPhase1()
    }
    
    // 🎯 1단계: 적당히 빠른 시작
    private func startPhase1() {
        print("📍 Phase 1: 적당히 빠른 시작 (\(phase1Duration)초)")
        currentPhase = 1
        spinningSpeed = phase1Speed
        startSpinTimer()
        
        // 1단계 → 2단계 전환
        DispatchQueue.main.asyncAfter(deadline: .now() + phase1Duration) { [weak self] in
            self?.startPhase2()
        }
    }
    
    // 🐌 2단계: 점진적 감속
    private func startPhase2() {
        print("📍 Phase 2: 점진적 감속 시작 (\(phase2Duration)초)")
        currentPhase = 2
        startGradualSlowdown()
        
        // 2단계 완료 후 종료
        DispatchQueue.main.asyncAfter(deadline: .now() + phase2Duration) { [weak self] in
            self?.stopRoulette()
        }
    }
    
    private func startSpinTimer() {
        spinTimer = Timer.scheduledTimer(withTimeInterval: spinningSpeed, repeats: true) { [weak self] _ in
            self?.updateHighlight()
        }
    }
    
    private func restartSpinTimer() {
        spinTimer?.invalidate()
        startSpinTimer()
    }
    
    private func updateHighlight() {
        guard !faces.isEmpty else { return }
        
        // 다음 얼굴로 이동
        currentHighlightedIndex = (currentHighlightedIndex + 1) % faces.count
        
        // 단계별 사운드와 햅틱
        switch currentPhase {
        case 1:
            // 1단계: 적당한 틱
            SoundManager.shared.playSpinSound()
            let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
            mediumFeedback.impactOccurred()
        case 2:
            // 2단계: 긴장감 있는 틱
            SoundManager.shared.playSpinSound()
            let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
            heavyFeedback.impactOccurred()
        default:
            break
        }
    }
    
    // 🐌 2단계에서 점진적으로 느려지는 타이머
    private func startGradualSlowdown() {
        let slowdownSteps = 12 // 12단계로 나누어 자연스럽게 감속
        let stepDuration = phase2Duration / Double(slowdownSteps)
        
        for step in 0..<slowdownSteps {
            let delay = stepDuration * Double(step)
            let progress = Double(step) / Double(slowdownSteps - 1)
            
            // 자연스러운 ease-out 곡선으로 속도 계산
            let easeOutProgress = 1 - pow(1 - progress, 1.5)
            let currentStepSpeed = phase2StartSpeed + (phase2EndSpeed - phase2StartSpeed) * easeOutProgress
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.currentPhase == 2 else { return }
                
                self.spinningSpeed = currentStepSpeed
                self.restartSpinTimer()
                
                print("🐌 Step \(step + 1)/\(slowdownSteps): speed = \(String(format: "%.2f", currentStepSpeed))초")
            }
        }
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
        currentPhase = 1
        spinStartTime = Date()
        spinningSpeed = phase1Speed
    }
    
    deinit {
        spinTimer?.invalidate()
    }
}
