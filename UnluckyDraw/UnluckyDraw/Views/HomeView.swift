//
//  HomeView.swift
//  UnluckyDraw
//
//  Created on 2025-06-16
//

import SwiftUI

struct HomeView: View {
    @State private var selectedMode: DrawMode?
    @State private var showingPhotoDrawCamera = false
    @State private var showingPhotoDrawGallery = false
    @State private var showingModeSelection = false
    @State private var pulseAnimation = false
    @State private var backgroundGradientOffset: CGFloat = 0
    @State private var logoRotation: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                animatedBackground
                
                VStack(spacing: 25) {
                    headerSection
                    
                    actionCardsSection
                    
                    Spacer()
                    footerSection
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .animation(.none)
        .transition(.identity)
        .fullScreenCover(isPresented: $showingPhotoDrawCamera) {
            PhotoDrawView(initialSourceType: .camera)
        }
        .fullScreenCover(isPresented: $showingPhotoDrawGallery) {
            PhotoDrawView(initialSourceType: .photoLibrary)
        }
    }
    
    // MARK: - UI Components
    
    private var animatedBackground: some View {
        ZStack {
            // Primary dark gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black, location: 0.0),
                    .init(color: Color.red.opacity(0.08), location: 0.3),
                    .init(color: Color.black.opacity(0.95), location: 0.7),
                    .init(color: Color.black, location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated overlay for depth
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.05),
                    Color.clear,
                    Color.red.opacity(0.05),
                    Color.clear
                ]),
                startPoint: UnitPoint(x: backgroundGradientOffset - 0.5, y: 0),
                endPoint: UnitPoint(x: backgroundGradientOffset + 0.5, y: 1)
            )
            .opacity(0.4)
        }
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                ZStack {
                    Text("💀")
                        .font(.system(size: 75))
                        .rotationEffect(.degrees(logoRotation))
                        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
                        .shadow(color: .red.opacity(0.6), radius: 15, x: 0, y: 8)
                        
                    Text("⚡")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                        .offset(x: 35, y: -10)
                        .opacity(pulseAnimation ? 1.0 : 0.3)
                        .rotationEffect(.degrees(-logoRotation))
                        
                    Text("⚡")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .offset(x: -30, y: 15)
                        .opacity(pulseAnimation ? 0.8 : 0.2)
                        .rotationEffect(.degrees(-logoRotation * 0.5))
                }
            }
            
            VStack(spacing: 8) {
                Text("UNLUCKY")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .tracking(4)
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.6), radius: 16, x: 0, y: 8)
                    .overlay(
                        Text("UNLUCKY")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.black.opacity(0.3))
                            .tracking(4)
                            .blur(radius: 1)
                            .offset(x: 1, y: 1)
                    )
                
                Text("DRAW")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(4)
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
                    .shadow(color: .red.opacity(0.6), radius: 12, x: 0, y: 6)
            }
            
            Text("Who will face the skull? 💀")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private var actionCardsSection: some View {
        VStack(spacing: 20) {
            // Camera card with dramatic styling
            EnhancedActionCard(
                title: "CAPTURE FATE",
                subtitle: "Take a new photo",
                description: "Capture your group's destiny",
                icon: "camera.fill",
                gradientColors: [Color.red.opacity(0.8), Color.orange.opacity(0.6)],
                glowColor: .red,
                action: {
                    HapticManager.impact(.heavy)
                    showingPhotoDrawCamera = true
                }
            )
            
            // Gallery card with contrasting style
            EnhancedActionCard(
                title: "CHOOSE VICTIMS",
                subtitle: "Select from gallery",
                description: "Pick from your photo collection",
                icon: "photo.on.rectangle.angled",
                gradientColors: [Color.gray.opacity(0.8), Color.black.opacity(0.6)],
                glowColor: .white,
                action: {
                    HapticManager.impact(.heavy)
                    showingPhotoDrawGallery = true
                }
            )
        }
        .padding(.horizontal, 24)
    }
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("⚡")
                    .font(.title2)
                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                
                Text("Ready to test your luck?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("⚡")
                    .font(.title2)
                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Animation Functions
    
    private func startAnimations() {
        // Only start animations after a small delay to prevent initial movement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Pulse animation only
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            
            // Logo rotation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                logoRotation = 360
            }
        }
    }
}

struct EnhancedActionCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let gradientColors: [Color]
    let glowColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 20) {
                // Header with icon
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Icon with glow
                    ZStack {
                        Circle()
                            .fill(glowColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .blur(radius: 8)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
                
                // Action indicator
                HStack {
                    Text("TAP TO START")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(1)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(24)
            .background(
                ZStack {
                    // Main gradient background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Shimmer effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .scaleEffect(x: 3, y: 1)
                        .offset(x: shimmerOffset * 400)
                        .clipped()
                    
                    // Border glow
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [glowColor.opacity(0.6), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: glowColor.opacity(0.4), radius: isPressed ? 8 : 15, x: 0, y: isPressed ? 4 : 8)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Start shimmer animation
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.0
            }
        }
    }
}

struct EnhancedPhotoCard: View {
    let title: String
    let description: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: gradientColors.first?.opacity(0.4) ?? .clear, radius: 12, x: 0, y: 6)
                    
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                VStack(spacing: 12) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.adaptiveLabel)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.adaptiveSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.adaptiveSecondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [gradientColors.first?.opacity(0.3) ?? .clear, .clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(isPressed ? 0.15 : 0.08),
                        radius: isPressed ? 8 : 16,
                        x: 0,
                        y: isPressed ? 4 : 8
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModeCard: View {
    let mode: DrawMode
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.primaryRed)
                    .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.adaptiveLabel)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.adaptiveSecondaryLabel)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.adaptiveTertiaryLabel)
            }
            .padding(20)
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}
