//
//  ContentView.swift
//  DriveLess
//
//  Ultra-compact sign-in with animated gradient - fits on screen without scrolling
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    // Create instances of our managers
    @StateObject private var locationManager = LocationManager()
    @StateObject private var authManager = AuthenticationManager()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var hapticManager: HapticManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    // MARK: - Animation State
    @State private var gradientOffset: CGFloat = 0
    
    // MARK: - Enhanced Earthy Color Palette
    private let primaryGreen = Color(red: 0.2, green: 0.4, blue: 0.2) // Dark forest green
    private let accentBrown = Color(red: 0.4, green: 0.3, blue: 0.2) // Rich brown
    private let lightGreen = Color(red: 0.7, green: 0.8, blue: 0.7) // Soft green
    private let warmBeige = Color(red: 0.9, green: 0.87, blue: 0.8) // Warm beige
    private let forestGreen = Color(red: 0.13, green: 0.27, blue: 0.13) // Deep forest
    private let oliveGreen = Color(red: 0.5, green: 0.6, blue: 0.4) // Olive green
    
    var body: some View {
        NavigationStack {
            Group {
                if authManager.isSignedIn {
                    // User is signed in - show main app
                    MainTabView(locationManager: locationManager, authManager: authManager, themeManager: themeManager, hapticManager: hapticManager, settingsManager: settingsManager)
                } else {
                    // User is not signed in - show ultra-compact sign-in screen
                    ultraCompactSignInView
                }
            }
        }
        .onAppear {
            // Start gradient animation
            startGradientAnimation()
            
            // Silently request location permission
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationPermission()
            }
        }
    }
    
    // MARK: - Ultra-Compact Sign-In View (NO SCROLLING)
    private var ultraCompactSignInView: some View {
        ZStack {
            // MARK: - Animated Gradient Background
            animatedGradientBackground
            
            // MARK: - Content Layer (ULTRA COMPACT)
            VStack(spacing: 0) {
                
                // MARK: - Compact Hero Section
                VStack(spacing: 12) { // Much smaller spacing
                    
                    // Minimal top spacer
                    Spacer()
                        .frame(height: 40)
                    
                    // Compact Logo/Title
                    VStack(spacing: 8) { // Reduced spacing
                        // Smaller logo
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [primaryGreen.opacity(0.9), lightGreen.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70) // Much smaller
                            .overlay(
                                Image(systemName: "map.fill")
                                    .font(.system(size: 30, weight: .bold)) // Smaller
                                    .foregroundColor(.white)
                            )
                            .shadow(color: primaryGreen.opacity(0.3), radius: 8, x: 0, y: 3)
                        
                        Text("DriveLess")
                            .font(.system(size: 32, weight: .bold)) // Smaller
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Text("Drive Less, Save Time")
                            .font(.system(size: 16, weight: .medium)) // Smaller
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    }
                    
                    // MUCH MORE COMPACT Features (SINGLE ROW)
                    HStack(spacing: 8) { // Horizontal layout to save space
                        compactFeatureItem(icon: "map.circle.fill", title: "Smart Routes")
                        compactFeatureItem(icon: "clock.fill", title: "Real-Time")
                        compactFeatureItem(icon: "location.circle.fill", title: "Save Fuel")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                
                // MARK: - Flexible Spacer
                Spacer()
                
                // MARK: - Compact Authentication Card
                compactAuthCard
                    .padding(.horizontal, 20)
                
                // MARK: - Bottom Spacer
                Spacer()
                    .frame(height: 30)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoading)
        .animation(.easeInOut(duration: 0.3), value: authManager.errorMessage)
    }
    
    // MARK: - Animated Gradient Background (SAME)
    private var animatedGradientBackground: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: forestGreen, location: 0.0 + gradientOffset),
                .init(color: primaryGreen, location: 0.3 + gradientOffset),
                .init(color: oliveGreen, location: 0.6 + gradientOffset),
                .init(color: accentBrown, location: 0.8 + gradientOffset),
                .init(color: forestGreen, location: 1.0 + gradientOffset)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Compact Authentication Card
    private var compactAuthCard: some View {
        VStack(spacing: 12) { // Reduced spacing
            
            // Show error message if there is one
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium)) // Smaller
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .transition(.opacity)
            }
            
            Text("Sign in to start planning routes")
                .font(.system(size: 16, weight: .semibold)) // Smaller
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            VStack(spacing: 10) { // Reduced spacing
                // Apple Sign-In Button (COMPACT)
                Button(action: {
                    hapticManager.buttonTap()
                    authManager.signInWithApple()
                }) {
                    HStack(spacing: 10) { // Reduced spacing
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "applelogo")
                                .font(.system(size: 16, weight: .medium)) // Smaller
                        }
                        
                        Text(authManager.isLoading ? "Signing in..." : "Continue with Apple")
                            .font(.system(size: 16, weight: .semibold)) // Smaller
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44) // Smaller
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                }
                .disabled(authManager.isLoading)
                .opacity(authManager.isLoading ? 0.7 : 1.0)
                
                // Compact Divider with "OR"
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("OR")
                        .font(.system(size: 12, weight: .semibold)) // Smaller
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10) // Reduced padding
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.vertical, 2) // Reduced padding
                
                // Google Sign-In Button (COMPACT)
                Button(action: {
                    hapticManager.buttonTap()
                    authManager.signInWithGoogle()
                }) {
                    HStack(spacing: 10) { // Reduced spacing
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: primaryGreen))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .medium)) // Smaller
                        }
                        
                        Text(authManager.isLoading ? "Signing in..." : "Continue with Google")
                            .font(.system(size: 16, weight: .semibold)) // Smaller
                    }
                    .foregroundColor(primaryGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44) // Smaller
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(primaryGreen.opacity(0.6), lineWidth: 2)
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .disabled(authManager.isLoading)
                .opacity(authManager.isLoading ? 0.7 : 1.0)
                
                // Compact Privacy Notice
                VStack(spacing: 4) { // Reduced spacing
                    HStack(spacing: 4) { // Reduced spacing
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 10, weight: .medium)) // Smaller
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Your data is secure and private")
                            .font(.system(size: 11, weight: .medium)) // Smaller
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("Sign in to sync your routes across devices")
                        .font(.system(size: 10)) // Smaller
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.top, 4) // Reduced padding
            }
        }
        .padding(18) // Reduced padding
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                )
        )
    }
    
    // MARK: - Compact Feature Item (HORIZONTAL)
    private func compactFeatureItem(icon: String, title: String) -> some View {
        VStack(spacing: 4) { // Very compact
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium)) // Smaller
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            
            Text(title)
                .font(.system(size: 11, weight: .semibold)) // Much smaller
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Animation Methods (SAME)
    private func startGradientAnimation() {
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) {
            gradientOffset = 0.3
        }
    }
}

#Preview {
    ContentView()
}
