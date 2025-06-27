//
//  FilterSelectionView.swift
//  UnluckyDraw
//
//  Created on 2025-06-27
//

import SwiftUI

struct FilterSelectionView: View {
    @Binding var selectedFilter: FilterEffect
    let onDismiss: () -> Void
    
    @State private var showAnimation = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Text("🎯")
                        .font(.system(size: 60))
                        .scaleEffect(showAnimation ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showAnimation)
                    
                    Text("Choose Your Game Mode")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(showAnimation ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: showAnimation)
                    
                    Text("Select the fate for the unlucky one")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(showAnimation ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(0.6), value: showAnimation)
                }
                .padding(.top, 40)
                
                // Filter Options
                VStack(spacing: 20) {
                    ForEach(FilterEffect.allCases) { filter in
                        FilterModeCard(
                            filter: filter,
                            isSelected: filter == selectedFilter,
                            onTap: {
                                HapticManager.selection()
                                selectedFilter = filter
                                
                                // Auto dismiss after selection
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDismiss()
                                }
                            }
                        )
                        .opacity(showAnimation ? 1.0 : 0.0)
                        .offset(x: showAnimation ? 0 : 50)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8 + Double(FilterEffect.allCases.firstIndex(of: filter) ?? 0) * 0.1), value: showAnimation)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Dismiss Button
                Button(action: onDismiss) {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                        
                        Text("Cancel")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .opacity(showAnimation ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(1.2), value: showAnimation)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            showAnimation = true
        }
    }
}

struct FilterModeCard: View {
    let filter: FilterEffect
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isSelected 
                            ? LinearGradient(
                                colors: [Color(filter.color).opacity(0.8), Color(filter.color).opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: filter.icon)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : Color(filter.color))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(filter.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(filter.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Color(filter.color) : .white.opacity(0.3))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected 
                        ? Color.black.opacity(0.8)
                        : Color.white.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color(filter.color).opacity(0.6) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? Color(filter.color).opacity(0.3) : Color.clear,
                radius: isSelected ? 12 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    FilterSelectionView(selectedFilter: .constant(.death)) {
        // Dismiss action
    }
}