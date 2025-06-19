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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.primaryRed.opacity(0.1),
                        Color.primaryOrange.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "tornado")
                            .font(.system(size: 60))
                            .foregroundColor(.primaryRed)
                        
                        Text("UnluckyDraw")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.darkGray)
                        
                        Text("Who's the unlucky one? 🎯")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    // Mode Selection Cards
                    VStack(spacing: 20) {
                        // Photo Draw Options - 두 개로 분리
                        PhotoModeCard(
                            title: "Take New Photo",
                            description: "Use camera to capture a group photo",
                            icon: "camera.fill",
                            action: {
                                HapticManager.selection()
                                showingPhotoDrawCamera = true
                            }
                        )
                        
                        PhotoModeCard(
                            title: "Choose from Gallery", 
                            description: "Select an existing photo from your gallery",
                            icon: "photo.fill.on.rectangle.fill",
                            action: {
                                HapticManager.selection()
                                showingPhotoDrawGallery = true
                            }
                        )
                        
                        // 기존 다른 모드들
                        ForEach([DrawMode.number, DrawMode.name], id: \.self) { mode in
                            ModeCard(mode: mode) {
                                HapticManager.selection()
                                selectedMode = mode
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Footer
                    Text("Choose your drawing method")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $selectedMode) { mode in
            switch mode {
            case .photo:
                // 이제 사용하지 않음 - 대신 위의 두 버튼 사용
                EmptyView()
            case .number:
                NumberDrawView()
            case .name:
                NameDrawView()
            }
        }
        .fullScreenCover(isPresented: $showingPhotoDrawCamera) {
            PhotoDrawView(initialSourceType: .camera)
        }
        .fullScreenCover(isPresented: $showingPhotoDrawGallery) {
            PhotoDrawView(initialSourceType: .photoLibrary)
        }
    }
}

// MARK: - Photo Mode Card
struct PhotoModeCard: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.primaryRed)
                    .frame(width: 50, height: 50)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.darkGray)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
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
                // Icon
                Image(systemName: mode.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.primaryRed)
                    .frame(width: 50, height: 50)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.darkGray)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views
struct NumberDrawView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Number Draw")
                .font(.largeTitle)
                .padding()
            
            Text("Coming Soon!")
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button("Back") {
                dismiss()
            }
            .buttonStyle()
            .padding()
        }
    }
}

struct NameDrawView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Name Draw")
                .font(.largeTitle)
                .padding()
            
            Text("Coming Soon!")
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button("Back") {
                dismiss()
            }
            .buttonStyle()
            .padding()
        }
    }
}

#Preview {
    HomeView()
}
