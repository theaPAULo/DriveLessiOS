//
//  ContentView.swift
//  DriveLess
//
//  Ultra-compact sign-in with unified theme system and loading screen
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
    
    // MARK: - Loading Screen State
    @State private var showLoadingScreen = true
    
    // MARK: - Animation State
    @State private var gradientOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            Group {
                if showLoadingScreen {
                    // Show loading screen first
                    LoadingScreenView {
                        // Callback when loading animation completes
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showLoadingScreen = false
                        }
                    }
                } else if authManager.isSignedIn {
                    // User is signed in - show main app
                    MainTabView(
                        locationManager: locationManager,
                        authManager: authManager,
                        themeManager: themeManager,
                        hapticManager: hapticManager,
                        settingsManager: settingsManager
                    )
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
                VStack(spacing: 8) {
                    // Hero icon (smaller)
                    Image(systemName: "map.circle.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.white.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    // Main title (smaller)
                    Text("DriveLess")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    // Subtitle (RESTORED ORIGINAL)
                    Text("Drive Less, Save Time")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    // MARK: - Compact Feature Row (3 items, smaller)
                    HStack(spacing: 24) {
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
    
    // MARK: - Animated Gradient Background (Original Earthy Colors)
    private var animatedGradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.13, green: 0.27, blue: 0.13), // Deep forest green
                Color(red: 0.2, green: 0.4, blue: 0.2),    // Primary green
                Color(red: 0.5, green: 0.6, blue: 0.4),    // Olive green
                Color(red: 0.4, green: 0.3, blue: 0.2)     // Rich brown
            ]),
            startPoint: UnitPoint(x: gradientOffset / 100, y: 0),
            endPoint: UnitPoint(x: (gradientOffset / 100) + 1, y: 1)
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Compact Authentication Card (Updated for OR divider spacing)
    private var compactAuthCard: some View {
        VStack(spacing: 16) {
            // Error message component
            if let errorMessage = authManager.errorMessage {
                errorMessageView(errorMessage)
            }
            
            // Sign-in buttons component (now includes OR divider)
            signInButton
            
            // Privacy notice component
            privacyNotice
        }
        .padding(20)
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
    
    // MARK: - Sign-In Buttons Component (Original with OR divider)
    private var signInButton: some View {
        VStack(spacing: 16) {
            // Title
            Text("Sign in to start planning routes")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            // Apple Sign-In Button (Dark Forest Green)
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
                            Color(red: 0.13, green: 0.27, blue: 0.13), // Deep forest green
                            Color(red: 0.2, green: 0.4, blue: 0.2).opacity(0.9) // Primary green
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
            }
            .disabled(authManager.isLoading)
            .opacity(authManager.isLoading ? 0.7 : 1.0)
            .scaleEffect(authManager.isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: authManager.isLoading)
            
            // OR Divider (RESTORED ORIGINAL)
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                
                Text("OR")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, 20)
            
            // Google Sign-In Button (Light theme)
            Button(action: {
                hapticManager.buttonTap()
                authManager.signInWithGoogle()
            }) {
                HStack(spacing: 10) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.13, green: 0.27, blue: 0.13)))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(authManager.isLoading ? "Signing in..." : "Continue with Google")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(red: 0.13, green: 0.27, blue: 0.13)) // Deep forest green
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.white.opacity(0.95)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.13, green: 0.27, blue: 0.13).opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
            }
            .disabled(authManager.isLoading)
            .opacity(authManager.isLoading ? 0.7 : 1.0)
            .scaleEffect(authManager.isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: authManager.isLoading)
        }
    }
    
    // MARK: - Privacy Notice Component (Original Friendly Version)
    private var privacyNotice: some View {
        VStack(spacing: 4) {
            Text("By continuing, you agree to our Terms of Service and Privacy Policy. We protect your data and don't share personal information")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
    }
    
    // MARK: - Compact Feature Item Component
    private func compactFeatureItem(icon: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
    }
    
    // MARK: - Card Background (Original Style)
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.6),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Animation Helper
    private func startGradientAnimation() {
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            gradientOffset = 100
        }
    }
}
