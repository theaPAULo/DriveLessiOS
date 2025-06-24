//
//  ContentView.swift
//  DriveLess
//
//  Ultra-compact sign-in with unified theme system
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
    
    // MARK: - Ultra-Compact Sign-In View (Using Theme System)
    private var ultraCompactSignInView: some View {
        ZStack {
            // MARK: - Animated Gradient Background (Using Theme)
            animatedGradientBackground
            
            // MARK: - Content Layer (ULTRA COMPACT)
            VStack(spacing: 0) {
                
                // MARK: - Compact Hero Section
                VStack(spacing: 12) {
                    
                    // Minimal top spacer
                    Spacer()
                        .frame(height: 40)
                    
                    // Compact Logo/Title
                    VStack(spacing: 8) {
                        // Logo using theme colors
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [themeManager.primary.opacity(0.9), themeManager.accent.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "map.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: themeManager.cardShadow(), radius: 8, x: 0, y: 3)
                        
                        Text("DriveLess")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Text("Drive Less, Save Time")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    }
                    
                    // Compact Features (SINGLE ROW)
                    HStack(spacing: 8) {
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
    
    // MARK: - Animated Gradient Background (Using Theme System)
    private var animatedGradientBackground: some View {
        themeManager.animatedGradient(offset: gradientOffset)
            .ignoresSafeArea()
    }
    
    // MARK: - Compact Authentication Card (Broken into components)
    private var compactAuthCard: some View {
        VStack(spacing: 20) {
            // Error message component
            if let errorMessage = authManager.errorMessage {
                errorMessageView(errorMessage)
            }
            
            // Sign-in buttons component (now includes both Apple and Google)
            signInButton
            
            // Privacy notice component
            privacyNotice
        }
        .padding(18)
        .background(cardBackground)
    }
    
    // MARK: - Error Message Component
    private func errorMessageView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 14, weight: .medium))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Sign-In Buttons Component (Unified Earthy Theme)
    private var signInButton: some View {
        VStack(spacing: 10) {
            // Title
            Text("Sign in to start planning routes")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            // Apple Sign-In Button (Dark Earthy Gradient)
            Button(action: {
                hapticManager.buttonTap()
                authManager.signInWithApple()
            }) {
                HStack(spacing: 10) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "applelogo")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(authManager.isLoading ? "Signing in..." : "Continue with Apple")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeManager.colors.forestGreen,
                            themeManager.colors.primaryGreen.opacity(0.9)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: themeManager.cardShadow(), radius: 6, x: 0, y: 3)
            }
            .disabled(authManager.isLoading)
            .opacity(authManager.isLoading ? 0.7 : 1.0)
            
            // Divider with "OR"
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.4))
                
                Text("OR")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.vertical, 2)
            
            // Google Sign-In Button (Light Earthy Gradient)
            Button(action: {
                hapticManager.buttonTap()
                authManager.signInWithGoogle()
            }) {
                HStack(spacing: 10) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.colors.primaryGreen))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(authManager.isLoading ? "Signing in..." : "Continue with Google")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(themeManager.colors.forestGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeManager.colors.warmBeige,
                            themeManager.colors.lightGreen.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: themeManager.cardShadow(), radius: 6, x: 0, y: 3)
            }
            .disabled(authManager.isLoading)
            .opacity(authManager.isLoading ? 0.7 : 1.0)
        }
    }
    
    // MARK: - Privacy Notice Component
    private var privacyNotice: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Your data is secure and private")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text("Sign in to sync your routes across devices")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Card Background Component
    private var cardBackground: some View {
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
    }
    
    // MARK: - Compact Feature Item
    private func compactFeatureItem(icon: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Animation Methods
    private func startGradientAnimation() {
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) {
            gradientOffset = 0.3
        }
    }
}

#Preview {
    ContentView()
}
