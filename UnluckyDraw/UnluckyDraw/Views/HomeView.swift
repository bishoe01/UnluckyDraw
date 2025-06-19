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
                    
                    // Photo Draw Cards - 개선된 UI
                    VStack(spacing: 24) {
                        // 카메라 카드
                        EnhancedPhotoCard(
                            title: "Take New Photo",
                            description: "Capture a group photo with your camera",
                            icon: "camera.fill",
                            gradientColors: [Color.primaryRed, Color.primaryOrange],
                            action: {
                                HapticManager.selection()
                                showingPhotoDrawCamera = true
                            }
                        )
                        
                        // 갤러리 카드
                        EnhancedPhotoCard(
                            title: "Choose from Gallery",
                            description: "Select an existing photo from your library",
                            icon: "photo.fill.on.rectangle.fill",
                            gradientColors: [Color.primaryOrange, Color.warningYellow],
                            action: {
                                HapticManager.selection()
                                showingPhotoDrawGallery = true
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Footer
                    Text("Pick your photo source to start the unlucky draw!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        // .fullScreenCover(item: $selectedMode) { mode in
        //     switch mode {
        //     case .photo:
        //         // 이제 사용하지 않음 - 대신 위의 두 버튼 사용
        //         EmptyView()
        //     case .number:
        //         NumberDrawView()
        //     case .name:
        //         NameDrawView()
        //     }
        // }
        .fullScreenCover(isPresented: $showingPhotoDrawCamera) {
            PhotoDrawView(initialSourceType: .camera)
        }
        .fullScreenCover(isPresented: $showingPhotoDrawGallery) {
            PhotoDrawView(initialSourceType: .photoLibrary)
        }
    }
}

// MARK: - Enhanced Photo Card
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
                // 아이콘 섹션
                ZStack {
                    // 배경 원
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: gradientColors.first?.opacity(0.3) ?? .clear, radius: 10, x: 0, y: 5)
                    
                    // 아이콘
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // 텍스트 섹션
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // 화살표 인디케이터
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(gradientColors.first ?? .primaryRed)
                    Spacer()
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(
                        color: Color.black.opacity(isPressed ? 0.15 : 0.08),
                        radius: isPressed ? 8 : 15,
                        x: 0,
                        y: isPressed ? 3 : 8
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
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

// MARK: - Placeholder Views - 임시 주석 처리

// struct NumberDrawView: View {
//     @Environment(\.dismiss) private var dismiss
//     
//     var body: some View {
//         VStack {
//             Text("Number Draw")
//                 .font(.largeTitle)
//                 .padding()
//             
//             Text("Coming Soon!")
//                 .font(.headline)
//                 .foregroundColor(.gray)
//             
//             Spacer()
//             
//             Button("Back") {
//                 dismiss()
//             }
//             .buttonStyle()
//             .padding()
//         }
//     }
// }
// 
// struct NameDrawView: View {
//     @Environment(\.dismiss) private var dismiss
//     
//     var body: some View {
//         VStack {
//             Text("Name Draw")
//                 .font(.largeTitle)
//                 .padding()
//             
//             Text("Coming Soon!")
//                 .font(.headline)
//                 .foregroundColor(.gray)
//             
//             Spacer()
//             
//             Button("Back") {
//                 dismiss()
//             }
//             .buttonStyle()
//             .padding()
//         }
//     }
// }

#Preview {
    HomeView()
}
