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
    let selectedFilter: FilterEffect
    let onPlayAgain: () -> Void
    let onClose: () -> Void
    
    @State private var showAnimation = false
    @State private var isSaving = false
    @State private var saveResult: Result<Void, ImageSaveError>? = nil
    @State private var showSaveAlert = false
    @State private var pulseAnimation = false
    @State private var backgroundGradientOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dynamic Background
            animatedBackground
            
            VStack(spacing: 0) {
                // Dramatic Header
                headerSection
                
                // Main Content Area
                mainImageSection
                
                Spacer(minLength: 20)
                
                // Action Buttons with improved design
                actionButtonsSection
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                showAnimation = true
            }
            
            // Background animation
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                backgroundGradientOffset = 1.0
            }
            
            // Strong haptic feedback
            HapticManager.notification(.warning)
            
            // Pulse animation for dramatic effect
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseAnimation.toggle()
            }
        }
        .alert("Photo Save Result", isPresented: $showSaveAlert) {
            Button("OK") {
                saveResult = nil
            }
            if case .failure(let error) = saveResult, case .permissionDenied = error {
                Button("Settings") {
                    openAppSettings()
                }
            }
        } message: {
            if let result = saveResult {
                switch result {
                case .success:
                    Text("✅ Photo saved successfully to your photo library!")
                case .failure(let error):
                    Text(error.userFriendlyMessage)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var animatedBackground: some View {
        ZStack {
            // Primary gradient background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black, location: 0.0),
                    .init(color: Color.red.opacity(0.15), location: 0.3),
                    .init(color: Color.black.opacity(0.95), location: 0.7),
                    .init(color: Color.black, location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated overlay gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.red.opacity(0.1),
                    Color.clear,
                    Color.orange.opacity(0.08),
                    Color.clear
                ]),
                startPoint: UnitPoint(x: backgroundGradientOffset - 0.5, y: 0),
                endPoint: UnitPoint(x: backgroundGradientOffset + 0.5, y: 1)
            )
            .opacity(0.6)
        }
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Skull emoji with pulse effect
            Text("💀")
                .font(.system(size: showAnimation ? 70 : 40))
                .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                .shadow(color: .red.opacity(0.8), radius: pulseAnimation ? 15 : 5)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showAnimation)
            
            // Game Over title with glow effect
            VStack(spacing: 8) {
                Text("UNLUCKY DRAW")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(3)
                
                Text("ELIMINATED")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange.opacity(0.8), .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .red.opacity(0.5), radius: 8)
                    .tracking(2)
                    .scaleEffect(showAnimation ? 1.0 : 0.3)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: showAnimation)
            }
        }
        .padding(.top, 40)
        .padding(.bottom, 30)
    }
    
    private var mainImageSection: some View {
        GeometryReader { _ in
            ZStack {
                // Background image with dramatic effect
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.red.opacity(0.6), .clear, .orange.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .scaleEffect(showAnimation ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: showAnimation)
                
                // Winner face highlight
                EnhancedWinnerDisplay(
                    winner: winner,
                    originalImage: image,
                    showAnimation: showAnimation
                )
            }
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: 400)
    }
    
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Save Photo Button - Primary action
            savePhotoButton
            
            // Secondary actions
            HStack(spacing: 14) {
                homeButton
                tryAgainButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .opacity(showAnimation ? 1.0 : 0.0)
        .offset(y: showAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
    }
    
    private var savePhotoButton: some View {
        Button(action: saveImageWithFrame) {
            HStack(spacing: 12) {
                ZStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .frame(width: 24)
                
                Text(isSaving ? "Saving to Photos..." : "Save Photo")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Primary gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.9),
                            Color.red.opacity(0.7),
                            Color.orange.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Shimmer effect when not saving
                    if !isSaving {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .rotationEffect(.degrees(30))
                        .scaleEffect(x: 3, y: 1)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: showAnimation)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .red.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(isSaving ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSaving)
        }
        .disabled(isSaving)
    }
    
    private var homeButton: some View {
        Button(action: {
            HapticManager.selection()
            onClose()
        }) {
            VStack(spacing: 8) {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Home")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Color.black.opacity(0.3)
                    
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var tryAgainButton: some View {
        Button(action: {
            HapticManager.impact()
            onPlayAgain()
        }) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .gray.opacity(0.7),
                        .gray.opacity(0.5)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Functions
    
    private func saveImageWithFrame() {
        guard !isSaving else { return }
        
        isSaving = true
        HapticManager.impact(.medium)
        
        ImageSaveManager.shared.saveImageWithWinnerFrame(
            originalImage: image,
            winner: winner,
            filter: selectedFilter
        ) { result in
            isSaving = false
            saveResult = result
            showSaveAlert = true
            
            switch result {
            case .success:
                HapticManager.notification(.success)
                SoundManager.shared.playCompleteSound()
            case .failure:
                HapticManager.notification(.error)
                SoundManager.shared.playErrorSound()
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Enhanced Winner Display

struct EnhancedWinnerDisplay: View {
    let winner: DetectedFace
    let originalImage: UIImage
    let showAnimation: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var glowIntensity: Double = 0.0
    @State private var rotationEffect: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            if let croppedFace = winner.croppedImage {
                VStack(spacing: 20) {
                    // Enhanced face display
                    Image(uiImage: croppedFace)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.red, .orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                        )
                        .shadow(color: .red.opacity(glowIntensity), radius: 20)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotationEffect))
                    
                    // Dramatic label
                    Text("💀 TARGET ELIMINATED")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .red.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.8))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.red.opacity(0.6), lineWidth: 1)
                                )
                        )
                        .shadow(color: .red.opacity(0.4), radius: 8)
                        .scaleEffect(scale * 0.8)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4)) {
                scale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.6)) {
                glowIntensity = 0.8
            }
            
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false).delay(1.0)) {
                rotationEffect = 360
            }
        }
    }
}


// MARK: - Custom Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ResultView(
        image: UIImage(systemName: "person.fill") ?? UIImage(),
        winner: DetectedFace(boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.3, height: 0.4), confidence: 0.95),
        totalFaces: 5,
        selectedFilter: .death,
        onPlayAgain: {},
        onClose: {}
    )
}
