//
//  LoadingScreenView.swift
//  DriveLess
//
//  Clean loading screen with breathing logo and rotating compass
//

import SwiftUI

struct LoadingScreenView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticManager: HapticManager
    
    // Animation states
    @State private var showContent: Bool = false
    @State private var logoScale: CGFloat = 0.95
    @State private var compassRotation: Double = 0
    @State private var loadingOpacity: Double = 0
    @State private var isComplete = false
    
    // Completion callback
    let onAnimationComplete: () -> Void
    
    var body: some View {
        ZStack {
            // MARK: - Consistent Background
            themeManager.animatedGradient(offset: 0)
                .ignoresSafeArea()
            
            if showContent {
                VStack(spacing: 40) {
                    
                    // MARK: - Breathing Logo Section
                    VStack(spacing: 16) {
                        // Main Logo Text with breathing animation
                        Text("DriveLess")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .scaleEffect(logoScale)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                                value: logoScale
                            )
                        
                        // Subtitle
                        Text("Drive Less, Save Time")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 1.0).delay(0.3), value: showContent)
                    
                    // MARK: - Rotating Compass Icon
                    VStack(spacing: 20) {
                        // Elegant compass icon
                        ZStack {
                            // Outer compass ring
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 50, height: 50)
                            
                            // Compass needle/pointer
                            Image(systemName: "location.north.circle.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                .rotationEffect(.degrees(compassRotation))
                                .animation(
                                    .linear(duration: 4.0)
                                    .repeatForever(autoreverses: false),
                                    value: compassRotation
                                )
                        }
                        
                        // Alternative: You can swap the above with this simpler compass:
                        /*
                        Image(systemName: "safari.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            .rotationEffect(.degrees(compassRotation))
                            .animation(
                                .linear(duration: 3.0)
                                .repeatForever(autoreverses: false),
                                value: compassRotation
                            )
                        */
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)
                    
                    // MARK: - Loading Text & Spinner
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.1)
                        
                        Text("Preparing your journey...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    }
                    .opacity(loadingOpacity)
                    .animation(.easeOut(duration: 0.6).delay(1.2), value: loadingOpacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Animation Sequence
    private func startAnimation() {
        // Initial haptic feedback
        hapticManager.impact(.light)
        
        // Show content with staggered entrance
        withAnimation(.easeOut(duration: 0.5)) {
            showContent = true
        }
        
        // Start breathing animation for logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            logoScale = 1.05
        }
        
        // Start compass rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            compassRotation = 360
        }
        
        // Show loading indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            loadingOpacity = 1.0
        }
        
        // Complete the sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            hapticManager.success()
            isComplete = true
            onAnimationComplete()
        }
    }
}
