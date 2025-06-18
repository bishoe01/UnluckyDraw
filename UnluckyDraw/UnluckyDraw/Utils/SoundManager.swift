//
//  SoundManager.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import Foundation
import AVFoundation

class SoundManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var spinSoundPlayer: AVAudioPlayer?
    
    static let shared = SoundManager()
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // 룰렛 스핀 사운드 (시스템 사운드 활용)
    func playSpinSound() {
        // 시스템 사운드 ID 사용 (클릭 사운드)
        AudioServicesPlaySystemSound(1104) // 틱 사운드
    }
    
    // "걸렸다!" 사운드 (재미있고 임팩트 있게)
    func playCaughtSound() {
        AudioServicesPlaySystemSound(1025) // 카메라 셔터 사운드 (재미있는 "땀!" 느낌)
    }
    
    // 에러 사운드  
    func playErrorSound() {
        AudioServicesPlaySystemSound(1006) // 에러 사운드
    }
    
    // 룰렛 스핀 시작 사운드 (재미있게!)
    func playStartSound() {
        AudioServicesPlaySystemSound(1003) // 메일 전송 사운드 (더 에너지 있는 느낌)
    }
    
    // 룰렛 완료 사운드
    func playCompleteSound() {
        AudioServicesPlaySystemSound(1013) // 완료 사운드
    }
}

// MARK: - 시스템 사운드 ID 참고
/*
주요 시스템 사운드 ID들:
1000: 새 메일
1001: 메일 전송
1002: 보이스메일
1003: 메일 받음
1004: SMS 받음
1005: 달력 알림
1006: 낮은 전력
1007: SMS 전송
1008: 트위트 전송
1009: 이미 스크린샷
1010: 사진 촬영
1011: 시이템 시작
1013: 트위터 받음
1020-1023: 터치톤
1025: 카메라 셔터
1104: 클릭 
1105: 트랙패드 클릭
1106: 스크린 캡처
*/
