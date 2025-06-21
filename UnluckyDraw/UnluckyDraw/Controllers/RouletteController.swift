//
//  RouletteController.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import AVFoundation
import Foundation
import SwiftUI

class RouletteController: ObservableObject {
    @Published var currentHighlightedIndex: Int = 0
    @Published var isSpinning = false
    @Published var spinningSpeed: Double = 0.1
    @Published var winner: DetectedFace?
    
    private var spinTimer: Timer?
    private var faces: [DetectedFace] = []
    
    private let totalSpinDuration: Double = 4.5
    private let phase1Duration: Double = 0.8
    private let phase2Duration: Double = 2.7
    private let phase3Duration: Double = 1.0
    
    private let phase1Speed: Double = 0.06
    private let phase2StartSpeed: Double = 0.11
    private let phase2EndSpeed: Double = 0.16
    private let phase3StartSpeed: Double = 0.16
    private let phase3EndSpeed: Double = 0.15 //
    
    @Published var currentPhase: Int = 1
    @Published var tensionLevel: Double = 0.0
    @Published var spinStartTime: Date = .init()
    
    func startRoulette(with faces: [DetectedFace]) {
        guard faces.count > 1 else {
            if let singleFace = faces.first {
                winner = singleFace
                SoundManager.shared.playCaughtSound()
            }
            return
        }
        
        self.faces = faces
        isSpinning = true
        winner = nil
        currentHighlightedIndex = 0
        currentPhase = 1
        spinStartTime = Date()
        spinningSpeed = phase1Speed
        
        SoundManager.shared.playStartSound()
        
        startPhase1()
    }
    
    private func startPhase1() {
        currentPhase = 1
        tensionLevel = 0.1
        spinningSpeed = phase1Speed
        startSpinTimer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + phase1Duration) { [weak self] in
            self?.startPhase2()
        }
    }
    
    private func startPhase2() {
        currentPhase = 2
        tensionLevel = 0.5
        startGradualSlowdown(from: phase2StartSpeed, to: phase2EndSpeed, duration: phase2Duration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + phase2Duration) { [weak self] in
            self?.startPhase3()
        }
    }
    
    private func startPhase3() {
        currentPhase = 3
        tensionLevel = 1.0
        
        spinningSpeed = phase3StartSpeed
        restartSpinTimer()
        
        startGradualSlowdownImmediate(from: phase3StartSpeed, to: phase3EndSpeed, duration: phase3Duration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + phase3Duration) { [weak self] in
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
        
        currentHighlightedIndex = (currentHighlightedIndex + 1) % faces.count
        
        switch currentPhase {
        case 1:
            
            SoundManager.shared.playSpinSound()
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            lightFeedback.impactOccurred()
        case 2:
            
            SoundManager.shared.playSpinSound()
            let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
            mediumFeedback.impactOccurred()
        case 3:
            
            SoundManager.shared.playSpinSound()
            let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
            heavyFeedback.impactOccurred(intensity: 1.0)
        default:
            break
        }
    }
    
    private func startGradualSlowdown(from startSpeed: Double, to endSpeed: Double, duration: Double) {
        let slowdownSteps = 12
        let stepDuration = duration / Double(slowdownSteps)
        
        for step in 0..<slowdownSteps {
            let delay = stepDuration * Double(step)
            let progress = Double(step) / Double(slowdownSteps - 1)
            
            let easeProgress = 1 - pow(1 - progress, 1.5)
            let currentStepSpeed = startSpeed + (endSpeed - startSpeed) * easeProgress
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isSpinning else { return }
                
                self.spinningSpeed = currentStepSpeed
                self.restartSpinTimer()
                

            }
        }
    }
    
    private func startGradualSlowdownImmediate(from startSpeed: Double, to endSpeed: Double, duration: Double) {
        let slowdownSteps = 10
        let stepDuration = duration / Double(slowdownSteps)
        
        for step in 1..<slowdownSteps {
            let delay = stepDuration * Double(step)
            let progress = Double(step) / Double(slowdownSteps - 1)
            
            let easeProgress = 1 - pow(1 - progress, 1.2)
            let currentStepSpeed = startSpeed + (endSpeed - startSpeed) * easeProgress
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isSpinning else { return }
                
                self.spinningSpeed = currentStepSpeed
                self.restartSpinTimer()
                
                self.tensionLevel = min(1.0, 0.8 + progress * 0.2)
                

            }
        }
    }
    
    private func stopRoulette() {
        isSpinning = false
        spinTimer?.invalidate()
        spinTimer = nil
        
        if !faces.isEmpty {
            let winnerIndex = currentHighlightedIndex
            var winnerFace = faces[winnerIndex]
            winnerFace.isWinner = true
            winner = winnerFace
        }
        
        SoundManager.shared.playCaughtSound()
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        tensionLevel = 0.0
    }
    
    func reset() {
        isSpinning = false
        spinTimer?.invalidate()
        spinTimer = nil
        currentHighlightedIndex = 0
        winner = nil
        faces.removeAll()
        currentPhase = 1
        tensionLevel = 0.0
        spinStartTime = Date()
        spinningSpeed = phase1Speed
    }
    
    deinit {
        spinTimer?.invalidate()
    }
}
